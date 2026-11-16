#!/usr/bin/env python3
"""vmfw_dns.py - filtering DNS forwarder that cooperates with vmfw.py.

Run it on the host (as root) next to vmfw.py; it imports vmfw.py for the
config/state handling. The guest should use the host's bridge address as its
resolver. There are no special DNS rules: other DNS servers are reachable or
not purely according to `default` and the entries.

  default "block": entries are the allow-list. Names that match no entry get
      NXDOMAIN. For a matching hostname/wildcard entry the A records of the
      upstream answer are added (with a timeout) to that entry's nft set, so
      the guest can connect to exactly the addresses it was just given.
  default "allow": entries are the block-list. Names that match an entry get
      NXDOMAIN, everything else is forwarded untouched.

Name matching: "example.com" matches exactly that name (and, if the config
has "subdomains": true, every name below it); "*.example.com" matches any
subdomain but not example.com itself.

Python 3.8+, standard library only.
"""
import argparse
import fcntl
import ipaddress
import os
import signal
import socket
import socketserver
import struct
import sys
import threading
import time

import vmfw

SIOCGIFADDR = 0x8915
SIOCGIFNETMASK = 0x891B
MAX_TTL = 86400
# Minimum seconds an address learned from a DNS answer stays open. Since vmfw checks
# every packet against the sets, an address that expires (answer TTLs are
# often 30-60 s) would cut off a long-lived connection (ssh, websocket,
# download) that the guest opened with it. An hour is a compromise between
# that and keeping stale addresses allowed.
MIN_TTL = 3600
UPSTREAM_TIMEOUT = 3.0

RCODE_FORMERR, RCODE_SERVFAIL, RCODE_NXDOMAIN, RCODE_NOTIMP = 1, 2, 3, 4


def log(msg):
    print("%s %s" % (time.strftime("%H:%M:%S"), msg), file=sys.stderr, flush=True)


# --------------------------------------------------------------------------
# DNS wire format (just what we need)
# --------------------------------------------------------------------------

def parse_question(msg):
    """Return (qname, qtype, end_of_question) of the single question."""
    if len(msg) < 12:
        raise ValueError("short")
    if struct.unpack("!H", msg[4:6])[0] != 1:
        raise ValueError("need exactly one question")
    off, labels = 12, []
    while True:
        if off >= len(msg):
            raise ValueError("truncated name")
        n = msg[off]
        if n == 0:
            off += 1
            break
        if n & 0xC0:
            raise ValueError("compressed name in question")
        labels.append(msg[off + 1:off + 1 + n].decode("latin-1"))
        off += 1 + n
    if off + 4 > len(msg):
        raise ValueError("truncated question")
    qtype = struct.unpack("!H", msg[off:off + 2])[0]
    return ".".join(labels).lower(), qtype, off + 4


def make_reply(query, qend, rcode):
    """Empty reply (no answers) carrying `rcode`, echoing the question."""
    flags = struct.unpack("!H", query[2:4])[0]
    out = 0x8000 | (flags & 0x7800) | (flags & 0x0100) | 0x0080 | rcode
    return query[:2] + struct.pack("!HHHHH", out, 1, 0, 0, 0) + query[12:qend]


def skip_name(msg, off):
    while True:
        if off >= len(msg):
            raise ValueError("truncated")
        n = msg[off]
        if n == 0:
            return off + 1
        if n & 0xC0 == 0xC0:
            return off + 2
        if n & 0xC0:
            raise ValueError("bad label")
        off += 1 + n


def a_records(resp):
    """[(ipv4, ttl)] from the answer section; [] on error or non-zero rcode."""
    try:
        flags, qd, an = struct.unpack("!HHH", resp[2:8])
        if flags & 0x000F:
            return []
        off = 12
        for _ in range(qd):
            off = skip_name(resp, off) + 4
        out = []
        for _ in range(an):
            off = skip_name(resp, off)
            rtype, rclass, ttl, rdlen = struct.unpack("!HHIH", resp[off:off + 10])
            off += 10
            if off + rdlen > len(resp):
                return out
            if rtype == 1 and rclass == 1 and rdlen == 4:
                out.append((socket.inet_ntoa(resp[off:off + 4]), ttl))
            off += rdlen
        return out
    except (struct.error, ValueError):
        return []


# --------------------------------------------------------------------------
# Upstream
# --------------------------------------------------------------------------

def forward_udp(upstreams, query):
    for host, port in upstreams:
        deadline = time.monotonic() + UPSTREAM_TIMEOUT
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            try:
                s.connect((host, port))
                s.send(query)
                while True:
                    left = deadline - time.monotonic()
                    if left <= 0:
                        break
                    s.settimeout(left)
                    resp = s.recv(65535)
                    if resp[:2] == query[:2]:
                        return resp
            except OSError:
                continue
    return None


def recv_exact(s, n):
    buf = b""
    while len(buf) < n:
        chunk = s.recv(n - len(buf))
        if not chunk:
            raise OSError("closed")
        buf += chunk
    return buf


def forward_tcp(upstreams, query):
    for host, port in upstreams:
        try:
            with socket.create_connection((host, port), UPSTREAM_TIMEOUT) as s:
                s.settimeout(UPSTREAM_TIMEOUT)
                s.sendall(struct.pack("!H", len(query)) + query)
                n = struct.unpack("!H", recv_exact(s, 2))[0]
                return recv_exact(s, n)
        except OSError:
            continue
    return None


def parse_upstream(text):
    host, _, port = text.partition(":")
    try:
        ipaddress.IPv4Address(host)
        return host, int(port) if port else 53
    except ValueError:
        raise vmfw.FwError("bad upstream %r (IPv4[:port])" % text)


def resolv_conf_upstreams():
    out = []
    try:
        with open("/etc/resolv.conf") as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2 and parts[0] == "nameserver":
                    try:
                        ipaddress.IPv4Address(parts[1])
                        out.append((parts[1], 53))
                    except ValueError:
                        pass  # IPv6 etc.
    except OSError:
        pass
    return out


# --------------------------------------------------------------------------
# The filter
# --------------------------------------------------------------------------

class Filter:
    def __init__(self, state_dir, listen, upstream_override):
        self.state_dir = state_dir
        self.listen = listen  # (ip, port): never use ourselves as upstream
        self.upstream_override = upstream_override
        self.lock = threading.Lock()
        self.live = {}        # (set, ip) -> monotonic expiry we set
        self._state = None
        self._mtime = None
        self._upstreams = []

    def state(self):
        """Current vmfw state; reloaded whenever state.json changes."""
        try:
            mtime = os.stat(vmfw.state_path(self.state_dir)).st_mtime_ns
        except OSError:
            return None
        if mtime != self._mtime:
            with self.lock:
                if mtime != self._mtime:  # nobody else reloaded meanwhile
                    self._mtime = mtime   # also on failure: don't retry/log in a loop
                    try:
                        st = vmfw.load_state(self.state_dir)
                    except vmfw.FwError as e:
                        log("cannot load state: %s" % e)
                        return self._state
                    self._state = st
                    ups = self.upstream_override or resolv_conf_upstreams()
                    self._upstreams = [u for u in ups if u != self.listen]
                    log("state loaded: default=%s, upstream=%s" % (
                        st["config"]["default"],
                        ", ".join("%s:%d" % u for u in self._upstreams) or "NONE"))
                    self._restore(st)
        return self._state

    def watch(self):
        """Poll for state changes, so that a reload (which empties the nft
        sets) is followed by restoring the learned addresses right away,
        not only when the next DNS query happens to arrive."""
        while True:
            time.sleep(0.5)
            try:
                self.state()
            except Exception as e:  # keep watching whatever happens
                log("ERROR    watcher: %s" % e)

    def _restore(self, st):
        """Put still-live learned addresses back into the freshly loaded sets
        (every vmfw reload replaces the table and so empties them).  Called with
        self.lock held."""
        valid = set()
        if st["config"]["default"] == "block":
            valid = {vmfw.set_name(e) for e in st["entries"] + st["dynamic"]
                     if e["kind"] in ("host", "wild")}
        now = time.monotonic()
        adds = []
        for (name, ip), expiry in list(self.live.items()):
            left = int(expiry - now)
            if name not in valid or left <= 5:  # entry gone, or about to expire
                del self.live[(name, ip)]
                continue
            adds.append("add element inet %s %s { %s timeout %ds }"
                        % (vmfw.TABLE, name, ip, left))
        if not adds:
            return
        try:
            vmfw.run_nft("\n".join(adds) + "\n")
            log("restored %d learned address(es) after reload" % len(adds))
        except vmfw.FwError as e:
            log("ERROR    could not restore learned addresses: %s" % e)

    def handle(self, query, tcp):
        try:
            qname, qtype, qend = parse_question(query)
        except ValueError as e:
            if len(query) >= 12:
                return query[:2] + struct.pack("!HHHHH", 0x8080 | RCODE_FORMERR, 0, 0, 0, 0)
            return None
        flags = struct.unpack("!H", query[2:4])[0]
        if flags & 0x8000:
            return None                      # a response, not a query
        if flags & 0x7800:
            return make_reply(query, qend, RCODE_NOTIMP)
        st = self.state()
        if st is None or not self._upstreams:
            log("SERVFAIL %s (no state or no upstream)" % qname)
            return make_reply(query, qend, RCODE_SERVFAIL)
        cfg = st["config"]
        matched = [e for e in st["entries"] + st["dynamic"]
                   if vmfw.name_matches(e, qname, cfg["subdomains"])]
        block_mode = cfg["default"] == "block"
        if bool(matched) != block_mode:      # not on allow-list / on block-list
            log("BLOCK    %s" % qname)
            return make_reply(query, qend, RCODE_NXDOMAIN)
        if qtype == 28 and not cfg["allow_ipv6"]:
            return make_reply(query, qend, 0)  # empty answer: no AAAA for you
        resp = (forward_tcp if tcp else forward_udp)(self._upstreams, query)
        if resp is None:
            log("SERVFAIL %s (upstream did not answer)" % qname)
            return make_reply(query, qend, RCODE_SERVFAIL)
        records = a_records(resp)
        if block_mode:
            self.learn(cfg, matched, records)
        log("ALLOW    %s -> %s" % (qname, ", ".join(ip for ip, _ in records) or "(no A records)"))
        return resp

    def learn(self, cfg, matched, records):
        """Open the firewall for the answered addresses, before the guest sees them."""
        items = []
        for ip, ttl in records:
            if not ipaddress.IPv4Address(ip).is_global:
                log("REFUSE   not opening non-global address %s" % ip)
                continue
            items.append((ip, min(max(ttl, MIN_TTL), MAX_TTL)))
        if not items:
            return
        now = time.monotonic()
        with self.lock:
            dels, adds = [], []
            for e in matched:
                name = vmfw.set_name(e)
                for ip, timeout in items:
                    if self.live.get((name, ip), 0) - now > 5:
                        # still present: replace it to refresh the timeout
                        dels.append("delete element inet %s %s { %s }" % (vmfw.TABLE, name, ip))
                    adds.append("add element inet %s %s { %s timeout %ds }"
                                % (vmfw.TABLE, name, ip, timeout))
                    self.live[(name, ip)] = now + timeout
            try:
                vmfw.run_nft("\n".join(dels + adds) + "\n")
            except vmfw.FwError:
                try:  # a delete failed (element already gone / table reloaded)
                    vmfw.run_nft("\n".join(adds) + "\n")
                except vmfw.FwError as e:
                    log("ERROR    could not update nft sets (run `vmfw.py apply`?): %s" % e)


# --------------------------------------------------------------------------
# Servers
# --------------------------------------------------------------------------

class UDPHandler(socketserver.BaseRequestHandler):
    def handle(self):
        data, sock = self.request
        if not self.server.client_ok(self.client_address[0]):
            return
        resp = self.server.flt.handle(data, tcp=False)
        if resp:
            sock.sendto(resp, self.client_address)


class TCPHandler(socketserver.BaseRequestHandler):
    def handle(self):
        s = self.request
        if not self.server.client_ok(self.client_address[0]):
            return
        s.settimeout(10)
        try:
            while True:
                n = struct.unpack("!H", recv_exact(s, 2))[0]
                resp = self.server.flt.handle(recv_exact(s, n), tcp=True)
                if resp is None:
                    return
                s.sendall(struct.pack("!H", len(resp)) + resp)
        except (OSError, struct.error):
            return


class ClientCheck:
    network = None

    def client_ok(self, addr):
        return self.network is None or ipaddress.ip_address(addr) in self.network


class UDPServer(ClientCheck, socketserver.ThreadingUDPServer):
    allow_reuse_address = True
    daemon_threads = True


class TCPServer(ClientCheck, socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True
    request_queue_size = 64


def iface_ioctl(ifname, req):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        res = fcntl.ioctl(s.fileno(), req, struct.pack("256s", ifname.encode()))
    except OSError as e:
        raise vmfw.FwError("cannot get IPv4 address of interface %s: %s" % (ifname, e))
    finally:
        s.close()
    return socket.inet_ntoa(res[20:24])


def main():
    ap = argparse.ArgumentParser(
        prog="vmfw_dns.py",
        description="Filtering DNS forwarder for vmfw (see vmfw.py). Listens on the "
                    "IPv4 address of the bridge named in the applied config.")
    ap.add_argument("--state-dir", default=os.environ.get("VMFW_STATE_DIR", vmfw.DEFAULT_STATE_DIR))
    ap.add_argument("--listen", metavar="IP", help="listen address (default: the bridge's IPv4 address)")
    ap.add_argument("--port", type=int, default=53)
    ap.add_argument("--upstream", metavar="IP[:PORT]", action="append",
                    help="upstream resolver (repeatable); default: the nameservers "
                         "in the host's /etc/resolv.conf")
    a = ap.parse_args()
    try:
        vmfw.require_root()
        st = vmfw.need_state(a.state_dir)
        network = None
        if a.listen:
            ipaddress.IPv4Address(a.listen)
            listen = a.listen
        else:
            br = st["config"]["bridge"]
            listen = iface_ioctl(br, SIOCGIFADDR)
            mask = iface_ioctl(br, SIOCGIFNETMASK)
            network = ipaddress.IPv4Network("%s/%s" % (listen, mask), strict=False)
        flt = Filter(a.state_dir, (listen, a.port), [parse_upstream(u) for u in a.upstream or []])
        servers = []
        for cls, handler in ((UDPServer, UDPHandler), (TCPServer, TCPHandler)):
            srv = cls((listen, a.port), handler)
            srv.flt, srv.network = flt, network
            servers.append(srv)
    except (vmfw.FwError, ValueError, OSError) as e:
        print("error: %s" % e, file=sys.stderr)
        return 1
    flt.state()
    threading.Thread(target=flt.watch, daemon=True).start()
    log("listening on %s:%d (udp+tcp)%s" % (
        listen, a.port, ", clients limited to %s" % network if network else ""))
    for srv in servers:
        threading.Thread(target=srv.serve_forever, daemon=True).start()
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        while True:
            time.sleep(3600)
    except (KeyboardInterrupt, SystemExit):
        log("bye")
    return 0


if __name__ == "__main__":
    sys.exit(main())
