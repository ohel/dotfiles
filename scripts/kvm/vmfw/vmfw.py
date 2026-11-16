#!/usr/bin/env python3
"""vmfw - nftables egress firewall for a virtual machine behind a Linux bridge.

Everything lives in one nftables table (`inet vm_fw`, plus `bridge vm_fw`
only while isolated). Every change re-renders the complete
ruleset from a JSON state file and loads it atomically with `nft -f -`.
Your existing tables (e.g. `ip vm_nat`) are never touched.

Python 3.8+, standard library only. Run `vmfw.py --help`.
"""
import argparse
import contextlib
import fcntl
import hashlib
import ipaddress
import json
import os
import re
import shutil
import socket
import stat
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlsplit

TABLE = "vm_fw"
DEFAULT_STATE_DIR = "/tmp/vmfw"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Ports implied by a URL scheme when the URL has no explicit port.
SCHEME_PORTS = {
    "http": 80, "https": 443, "ws": 80, "wss": 443,
    "ssh": 22, "ftp": 21, "git": 9418,
}

CONFIG_KEYS = {"interface", "default", "log_blocked", "allow_ipv6",
               "subdomains", "host_access", "entries"}

IFNAME_RE = re.compile(r"^[A-Za-z0-9_.\-]{1,15}$")
HOST_RE = re.compile(r"^[A-Za-z0-9_]([A-Za-z0-9_.\-]{0,251}[A-Za-z0-9_])?\.?$")


class FwError(Exception):
    pass


def warn(msg):
    print("warning: " + msg, file=sys.stderr)


# --------------------------------------------------------------------------
# Entry parsing
# --------------------------------------------------------------------------

def parse_ports(value):
    """'80', '80,443', '8000-8100', [80, '443'] -> sorted [[lo, hi], ...]"""
    if value is None:
        return []
    if isinstance(value, (int, str)):
        value = [value]
    out = []
    for item in value:
        for part in str(item).split(","):
            part = part.strip()
            if not part:
                continue
            m = re.fullmatch(r"(\d{1,5})(?:-(\d{1,5}))?", part)
            if not m:
                raise FwError("bad port expression %r" % part)
            lo = int(m.group(1))
            hi = int(m.group(2) or lo)
            if not 1 <= lo <= hi <= 65535:
                raise FwError("port out of range: %r" % part)
            out.append((lo, hi))
    merged = []
    for lo, hi in sorted(set(out)):
        if merged and lo <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], hi)
        else:
            merged.append([lo, hi])
    return merged


def parse_target(s):
    """Parse a target string into (target, proto, ports).

    Accepted forms:
      1.2.3.4   10.0.0.0/8   example.com
      example.com:443   example.com:80,443,8000-8100
      tcp:example.com:443   udp:1.2.3.4:53   icmp:example.com
      https://example.com/path   http://example.com:8080
      *.example.com   (wildcard: subdomains only, resolved via the DNS filter)
    """
    s = s.strip()
    proto = None
    ports = []
    if "://" in s:
        u = urlsplit(s)
        scheme = u.scheme.lower()
        if not u.hostname:
            raise FwError("no host in URL %r" % s)
        try:
            port = u.port
        except ValueError:
            raise FwError("bad port in URL %r" % s)
        if port:
            ports = [[port, port]]
        elif scheme in SCHEME_PORTS:
            ports = [[SCHEME_PORTS[scheme]] * 2]
        else:
            raise FwError("URL %r: unknown scheme, give an explicit port" % s)
        return u.hostname, "tcp", ports

    m = re.match(r"^(tcp|udp|icmp):(.*)$", s, re.I)
    if m:
        proto = m.group(1).lower()
        s = m.group(2)
    if s.count(":") == 1:
        s, p = s.split(":")
        ports = parse_ports(p)
    elif s.count(":") > 1:
        raise FwError("IPv6 is not supported: %r" % s)
    return s.strip(), proto, ports


def classify_target(target):
    """Return (kind, canonical_target). kind is 'net', 'host' or 'wild'."""
    if not target:
        raise FwError("empty target")
    if target.startswith("*."):
        kind, rest = classify_target(target[2:])
        if kind != "host":
            raise FwError("bad wildcard %r (use *.example.com)" % target)
        return "wild", "*." + rest
    if re.fullmatch(r"[0-9./]+", target):
        try:
            net = ipaddress.IPv4Network(target, strict=True)
        except ValueError as e:
            raise FwError("bad IPv4 address/network %r: %s" % (target, e))
        text = str(net.network_address) if net.prefixlen == 32 else str(net)
        return "net", text
    host = target.lower()
    try:
        host = host.encode("idna").decode("ascii")
    except UnicodeError:
        raise FwError("bad hostname %r" % target)
    if not HOST_RE.match(host):
        raise FwError("bad hostname %r" % target)
    return "host", host.rstrip(".")


def make_entry(spec, source, extra_ports=None, extra_proto=None,
               extra_comment=None):
    """Build an (unresolved) entry from a string or dict spec."""
    comment = extra_comment
    if isinstance(spec, dict):
        unknown = set(spec) - {"host", "ports", "proto", "comment"}
        if unknown:
            raise FwError("unknown entry keys %s in %r" % (sorted(unknown), spec))
        if "host" not in spec:
            raise FwError("entry object needs a \"host\": %r" % spec)
        target, proto, ports = parse_target(str(spec["host"]))
        if spec.get("proto"):
            proto = str(spec["proto"]).lower()
        if spec.get("ports") is not None:
            ports = parse_ports(spec["ports"])
        comment = spec.get("comment", comment)
    elif isinstance(spec, str):
        target, proto, ports = parse_target(spec)
    else:
        raise FwError("bad entry %r (want string or object)" % (spec,))
    if extra_proto and not proto:
        proto = extra_proto
    if extra_ports and not ports:
        ports = parse_ports(extra_ports)
    if proto not in (None, "tcp", "udp", "icmp"):
        raise FwError("bad protocol %r (tcp, udp, icmp)" % proto)
    if proto == "icmp" and ports:
        raise FwError("ports make no sense with icmp: %r" % spec)
    kind, target = classify_target(target)
    return {"target": target, "kind": kind,
            "proto": proto, "ports": ports, "comment": comment or "",
            "source": source, "addrs": [], "resolved_at": 0}


def entry_text(e):
    t = e["target"]
    if e["proto"]:
        t = e["proto"] + ":" + t
    if e["ports"]:
        t += ":" + ",".join(str(a) if a == b else "%d-%d" % (a, b)
                            for a, b in e["ports"])
    return t


def entry_key(e):
    return (e["target"], e["proto"], json.dumps(e["ports"]))


# --------------------------------------------------------------------------
# Resolution
# --------------------------------------------------------------------------

def dns_lookup(host):
    infos = socket.getaddrinfo(host, None, socket.AF_INET, socket.SOCK_STREAM)
    return sorted({i[4][0] for i in infos})


def resolve_entries(entries, previous, strict=False):
    """Fill in e['addrs'].  `previous` maps host -> (addrs, timestamp) and is
    used as a fallback if a lookup fails (unless strict)."""
    memo = {}
    now = int(time.time())
    for e in entries:
        if e["kind"] == "net":
            e["addrs"], e["resolved_at"] = [e["target"]], now
            continue
        if e["kind"] == "wild":  # nothing to pre-resolve; the DNS filter feeds it
            e["addrs"], e["resolved_at"] = [], 0
            continue
        host = e["target"]
        if host not in memo:
            try:
                memo[host] = (dns_lookup(host), now)
            except OSError as ex:
                if strict:
                    raise FwError("cannot resolve %s: %s" % (host, ex))
                old = previous.get(host)
                if old:
                    warn("cannot resolve %s (%s); keeping previous addresses" % (host, ex))
                    memo[host] = old
                else:
                    warn("cannot resolve %s (%s); entry has NO effect" % (host, ex))
                    memo[host] = ([], 0)
        e["addrs"], e["resolved_at"] = memo[host]


def previous_addrs(state):
    prev = {}
    if state:
        for e in state.get("entries", []) + state.get("dynamic", []):
            if e["kind"] == "host" and e["addrs"]:
                prev[e["target"]] = (e["addrs"], e["resolved_at"])
    return prev


# --------------------------------------------------------------------------
# Config / settings
# --------------------------------------------------------------------------

def check_ifname(name, what):
    if not isinstance(name, str) or not IFNAME_RE.match(name):
        raise FwError("bad interface name for %s: %r" % (what, name))
    return name


def parse_host_entry(s):
    s = str(s).strip().lower()
    if s == "*":
        return {"proto": None, "ports": []}
    if s == "icmp":
        return {"proto": "icmp", "ports": []}
    m = re.fullmatch(r"(tcp|udp):(.+)", s)
    if not m:
        raise FwError("bad host_access item %r (*, icmp, tcp:PORTS, udp:PORTS)" % s)
    ports = parse_ports(m.group(2))
    if not ports:
        raise FwError("no ports in host_access item %r" % s)
    return {"proto": m.group(1), "ports": ports}


def normalize_settings(cfg):
    default = cfg.get("default")
    if default not in ("allow", "block"):
        raise FwError('"default" is required and must be "allow" or "block"')
    for k in ("log_blocked", "allow_ipv6", "subdomains"):
        if k in cfg and not isinstance(cfg[k], bool):
            raise FwError('"%s" must be true or false' % k)
    ha = cfg.get("host_access", ["icmp", "udp:67"])
    if not isinstance(ha, list):
        raise FwError('"host_access" must be a list, e.g. ["icmp", "udp:67"]')
    return {
        "bridge": check_ifname(cfg.get("interface", "vmbridge"), "interface"),
        "default": default,
        "log_blocked": cfg.get("log_blocked", False),
        "allow_ipv6": cfg.get("allow_ipv6", False),
        "subdomains": cfg.get("subdomains", False),
        "host_allow": [parse_host_entry(x) for x in ha],
    }


def load_config(path):
    try:
        with open(path) as f:
            raw = json.load(f)
    except OSError as e:
        raise FwError("cannot read config: %s" % e)
    except json.JSONDecodeError as e:
        raise FwError("config %s is not valid JSON: %s" % (path, e))
    if not isinstance(raw, dict):
        raise FwError("config must be a JSON object")
    unknown = {k for k in raw if k not in CONFIG_KEYS}
    if unknown:
        raise FwError("unknown config keys: %s" % sorted(unknown))
    return raw


# --------------------------------------------------------------------------
# Ruleset rendering
# --------------------------------------------------------------------------

def set_name(e):
    """Name of the nft set holding the IPs of a hostname/wildcard entry.
    Derived from the entry itself so the DNS daemon needs no extra mapping."""
    return "h_" + hashlib.sha1(json.dumps(entry_key(e)).encode()).hexdigest()[:12]


def name_matches(e, qname, subdomains=False):
    """Does DNS name `qname` (lowercase, no trailing dot) match entry `e`?
    Hostname entries match exactly (and, with `subdomains`, also anything below
    them); '*.x.com' always matches subdomains, never x.com itself."""
    if e["kind"] == "host":
        return qname == e["target"] or (subdomains and qname.endswith("." + e["target"]))
    if e["kind"] == "wild":
        return qname.endswith(e["target"][1:])
    return False


def sanitize_comment(s):
    return re.sub(r"[^A-Za-z0-9._:/ ,\-]", "_", s)[:100]


def fmt_ports(ports):
    items = [str(a) if a == b else "%d-%d" % (a, b) for a, b in ports]
    return items[0] if len(items) == 1 else "{ " + ", ".join(items) + " }"


def fmt_addrs(addrs):
    nets = ipaddress.collapse_addresses(ipaddress.IPv4Network(a) for a in addrs)
    items = [str(n.network_address) if n.prefixlen == 32 else str(n) for n in nets]
    if not items:
        return None
    return "ip daddr " + (items[0] if len(items) == 1 else "{ " + ", ".join(items) + " }")


def entry_rules(e, verdict, log=False, match=None):
    """nft rule lines for one entry (several if proto is unspecified but ports
    are given, or if logging adds a separate log rule before each)."""
    if match is None:
        if not e["addrs"]:
            return ["# skipped (no addresses): %s" % sanitize_comment(entry_text(e))]
        match = fmt_addrs(e["addrs"])
    label = e["target"] + (" - " + e["comment"] if e["comment"] else "")
    tail = 'counter %s comment "%s"' % (
        verdict, sanitize_comment("%s %s" % ("allow" if verdict == "accept" else "block", label)))
    proto, ports = e["proto"], e["ports"]
    if proto == "icmp":
        heads = [match + " ip protocol icmp"]
    elif ports:
        heads = ["%s %s dport %s" % (match, p, fmt_ports(ports))
                 for p in ([proto] if proto else ["tcp", "udp"])]
    elif proto:
        heads = ["%s meta l4proto %s" % (match, proto)]
    else:
        heads = [match]
    out = []
    for h in heads:
        if log:
            # separate rule: a rate-limited log must not gate the verdict
            out.append('%s limit rate 10/second log prefix "vmfw-block: "' % h)
        out.append("%s %s" % (h, tail))
    return out


def render(state):
    """Render the complete `inet vm_fw` ruleset for a state dict."""
    s = state["config"]
    br = s["bridge"]
    kill = state.get("killswitch")
    entries = state["entries"] + state["dynamic"]
    ind = "\t\t"

    # No special DNS handling here: external DNS is just traffic, decided by
    # `default` and the entries. (Traffic to the host's own resolver,
    # vmfw_dns.py, goes through host_in.)
    egress = [ind + "ct state invalid counter drop"]
    sets = []
    if s["default"] == "block":
        # entries are the allow-list; hostnames/wildcards are backed by sets
        # that start with the pre-resolved IPs and that vmfw_dns.py adds to
        seen = set()
        for e in entries:
            if e["kind"] in ("host", "wild"):
                n = set_name(e)
                if n not in seen:
                    seen.add(n)
                    elems = sorted(set(e["addrs"]))
                    sets.append("\tset %s {\n\t\ttype ipv4_addr\n\t\tflags timeout\n%s\t}" % (
                        n, "\t\telements = { %s }\n" % ", ".join(elems) if elems else ""))
                egress += [ind + r for r in
                           entry_rules(e, "accept", match="ip daddr @" + n)]
            else:
                egress += [ind + r for r in entry_rules(e, "accept")]
        if s["log_blocked"]:
            egress.append(ind + 'limit rate 10/second log prefix "vmfw-block: "')
        egress.append(ind + 'counter drop comment "vmfw default block"')
    else:
        # entries are the block-list; wildcards are enforced by the DNS filter only
        for e in entries:
            if e["kind"] == "wild":
                egress.append(ind + "# wildcard %s: enforced by the DNS filter only"
                              % sanitize_comment(e["target"]))
            else:
                egress += [ind + r for r in entry_rules(e, "drop", s["log_blocked"])]
        egress.append(ind + 'counter accept comment "vmfw default allow"')

    host_in = [ind + "ct state established,related counter accept",
               ind + "ct state invalid counter drop"]
    # What the guest may reach on the host itself: an allow-list, everything
    # else is dropped. DNS (where vmfw_dns.py listens) is always open.
    for p in ("udp", "tcp"):
        host_in.append(ind + '%s dport 53 counter accept comment "vmfw dns"' % p)
    for h in s["host_allow"]:
        if h["proto"] is None:
            head = ""
        elif h["proto"] == "icmp":
            head = "ip protocol icmp "
        else:
            head = "%s dport %s " % (h["proto"], fmt_ports(h["ports"]))
        host_in.append(ind + '%scounter accept comment "vmfw host allow"' % head)
    if s["log_blocked"]:
        host_in.append(ind + 'limit rate 10/second log prefix "vmfw-host-block: "')
    host_in.append(ind + 'counter drop comment "vmfw host block"')

    fwd = []
    if kill:
        fwd.append('iifname "%s" counter drop comment "vmfw LOCKDOWN"' % br)
        fwd.append('oifname "%s" counter drop comment "vmfw LOCKDOWN"' % br)
    if not s["allow_ipv6"]:
        fwd.append('iifname "%s" meta nfproto ipv6 counter drop comment "vmfw no ipv6"' % br)
    fwd.append('iifname "%s" jump egress' % br)

    inp = []
    if kill == "all":
        inp.append('iifname "%s" counter drop comment "vmfw LOCKDOWN"' % br)
    if not s["allow_ipv6"]:
        inp.append('iifname "%s" meta nfproto ipv6 counter drop comment "vmfw no ipv6"' % br)
    inp.append('iifname "%s" jump host_in' % br)

    out = ["add table inet %s" % TABLE,
           "delete table inet %s" % TABLE,
           "table inet %s {" % TABLE] + sets + [
           "\tchain egress {"] + egress + ["\t}",
           "\tchain host_in {"] + host_in + ["\t}",
           "\tchain forward {",
           "\t\ttype filter hook forward priority 0; policy accept;"]
    out += [ind + x for x in fwd] + ["\t}", "\tchain input {",
           "\t\ttype filter hook input priority 0; policy accept;"]
    out += [ind + x for x in inp] + ["\t}", "}"]
    return "\n".join(out) + "\n"


def render_bridge_isolate(state):
    """L2 cut of the VM's tap: nothing enters from it (pre) and nothing is
    delivered to it (post: covers other VMs, the host, flooded/broadcast)."""
    tap = state["isolate_tap"]
    return ("add table bridge %s\ndelete table bridge %s\n"
            "table bridge %s {\n"
            "\tchain pre {\n"
            "\t\ttype filter hook prerouting priority -200; policy accept;\n"
            '\t\tiifname "%s" counter drop comment "vmfw ISOLATE in"\n'
            "\t}\n"
            "\tchain post {\n"
            "\t\ttype filter hook postrouting priority -200; policy accept;\n"
            '\t\toifname "%s" counter drop comment "vmfw ISOLATE out"\n'
            "\t}\n}\n" % (TABLE, TABLE, TABLE, tap, tap))


# --------------------------------------------------------------------------
# nft + state handling
# --------------------------------------------------------------------------

def nft_bin():
    for cand in (shutil.which("nft"), "/usr/sbin/nft", "/sbin/nft", "/usr/bin/nft"):
        if cand and os.access(cand, os.X_OK):
            return cand
    raise FwError("nft not found")


def run_nft(script, check=False):
    cmd = [nft_bin()] + (["-c"] if check else []) + ["-f", "-"]
    p = subprocess.run(cmd, input=script, text=True, capture_output=True)
    if p.returncode != 0:
        raise FwError("nft failed:\n" + p.stderr.strip())


def delete_tables(families=("inet", "bridge")):
    for fam in families:
        try:
            run_nft("add table %s %s\ndelete table %s %s\n" % (fam, TABLE, fam, TABLE))
        except FwError as e:
            if fam == "inet":
                raise
            warn("could not remove bridge table (ignored): %s" % e)


def install(state, check=False):
    """Load the ruleset described by `state`.  Atomic per table."""
    run_nft(render(state), check=check)
    if state.get("killswitch") == "all":
        try:
            run_nft(render_bridge_isolate(state), check=check)
        except FwError as e:
            warn("inet isolate rules are active, but the bridge-level part failed:\n%s" % e)
    elif not check:
        delete_tables(("bridge",))


def require_root():
    if os.geteuid() != 0:
        raise FwError("must be root (use sudo)")


@contextlib.contextmanager
def locked(state_dir):
    os.makedirs(state_dir, mode=0o700, exist_ok=True)
    check_state_dir(state_dir)
    with open(os.path.join(state_dir, "lock"), "w") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        yield


def state_path(state_dir):
    return os.path.join(state_dir, "state.json")


def check_state_dir(state_dir):
    """Refuse a state dir somebody else could have planted or can modify.
    Matters because the default lives in world-writable /tmp and the state
    is rendered into nft rules by root."""
    try:
        st = os.lstat(state_dir)
    except FileNotFoundError:
        return
    if not stat.S_ISDIR(st.st_mode):
        raise FwError("state dir %s is not a real directory (symlink?)" % state_dir)
    if st.st_uid != os.geteuid() or st.st_mode & 0o077:
        raise FwError("state dir %s must be owned by the current user and mode 0700; "
                      "remove it or use --state-dir" % state_dir)


def load_state(state_dir):
    check_state_dir(state_dir)
    try:
        with open(state_path(state_dir)) as f:
            st = json.load(f)
    except FileNotFoundError:
        return None
    except json.JSONDecodeError as e:
        raise FwError("state file corrupt: %s" % e)
    return st


def save_state(state_dir, st):
    fd, tmp = tempfile.mkstemp(dir=state_dir)
    with os.fdopen(fd, "w") as f:
        json.dump(st, f, indent=1)
    os.chmod(tmp, 0o600)
    os.replace(tmp, state_path(state_dir))


def need_state(state_dir):
    st = load_state(state_dir)
    if not st or not st.get("applied_from"):
        raise FwError("no firewall configured yet; run `vmfw.py apply` first")
    return st


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

def cmd_apply(a):
    path = os.path.abspath(a.config)
    raw = load_config(path)
    entries = [make_entry(x, "config") for x in raw.get("entries", [])]
    settings = normalize_settings(raw)
    dry = a.dry_run
    if not dry:
        require_root()

    def work(old):
        resolve_entries(entries, previous_addrs(old), a.strict)
        dynamic = [] if (a.reset_dynamic or not old) else old.get("dynamic", [])
        st = {"config": settings, "entries": entries,
              "dynamic": dynamic, "killswitch": (old or {}).get("killswitch"),
              "isolate_tap": (old or {}).get("isolate_tap"),
              "applied_from": path, "applied_at": int(time.time())}
        if st["killswitch"]:
            warn("VM is %s; run `unblock` to lift it" % ("ISOLATED" if st["killswitch"] == "all" else "BLOCKED"))
        if dry:
            sys.stdout.write(render(st))
            if st["killswitch"] == "all":
                sys.stdout.write(render_bridge_isolate(st))
            return
        install(st, check=a.check)
        if a.check:
            print("ruleset OK (nft -c)")
            return
        save_state(a.state_dir, st)
        print("applied: default=%s, %d config entries, %d dynamic entries"
              % (settings["default"], len(entries), len(dynamic)))

    if dry:
        try:
            old = load_state(a.state_dir)
        except (OSError, FwError):
            old = None
        work(old)
    else:
        with locked(a.state_dir):
            work(load_state(a.state_dir))


def cmd_add(a):
    require_root()
    with locked(a.state_dir):
        st = need_state(a.state_dir)
        new = [make_entry(sp, "dynamic", a.ports, a.proto, a.comment)
               for sp in a.specs]
        resolve_entries(new, previous_addrs(st), strict=True)
        existing = {entry_key(e) for e in st["entries"]}
        for e in new:
            if entry_key(e) in existing:
                raise FwError("%s is already in the config file" % entry_text(e))
        keys = {entry_key(e) for e in new}
        st["dynamic"] = [e for e in st["dynamic"] if entry_key(e) not in keys] + new
        install(st)
        save_state(a.state_dir, st)
        for e in new:
            print("added %s -> %s" % (entry_text(e), ", ".join(e["addrs"])))


def cmd_remove(a):
    require_root()
    with locked(a.state_dir):
        st = need_state(a.state_dir)
        keep = list(st["dynamic"])
        removed = []
        for sp in a.specs:
            t = make_entry(sp, "dynamic")
            detail = bool(t["proto"] or t["ports"])
            hit = [e for e in keep if e["target"] == t["target"]
                   and (not detail or (e["proto"] == t["proto"] and e["ports"] == t["ports"]))]
            if not hit:
                in_cfg = any(e["target"] == t["target"] for e in st["entries"])
                raise FwError("no dynamic entry matches %r%s" % (
                    sp, " (it is in the config file; edit it and re-apply)" if in_cfg else ""))
            keep = [e for e in keep if e not in hit]
            removed += hit
        st["dynamic"] = keep
        install(st)
        save_state(a.state_dir, st)
        for e in removed:
            print("removed %s" % entry_text(e))


def set_lockdown(a, level, tap=None):
    require_root()
    with locked(a.state_dir):
        st = load_state(a.state_dir)
        if not st:
            st = {"config": normalize_settings({"default": "allow"}), "entries": [],
                  "dynamic": [], "killswitch": None, "isolate_tap": None,
                  "applied_from": None,
                  "applied_at": 0}
        st["killswitch"] = level
        st["isolate_tap"] = tap
        install(st)
        save_state(a.state_dir, st)


def cmd_block(a):
    set_lockdown(a, "internet")
    print("BLOCKED: VM <-> internet cut (host access per host_access); "
          "`unblock` to lift")


def cmd_isolate(a):
    set_lockdown(a, "all", check_ifname(a.tap, "tap"))
    print("ISOLATED: ALL traffic from the VM is blocked (incl. host/ssh); "
          "`unblock` to lift")


def cmd_unblock(a):
    require_root()
    with locked(a.state_dir):
        st = load_state(a.state_dir)
        if not st or not st.get("killswitch"):
            print("not blocked or isolated")
            return
        if not st.get("applied_from"):
            # only a stub created by block/isolate without a prior apply
            delete_tables()
            os.unlink(state_path(a.state_dir))
            print("unblocked; no config was applied, so all rules removed")
            return
        st["killswitch"] = None
        st["isolate_tap"] = None
        install(st)
        save_state(a.state_dir, st)
        print("unblocked; normal rules restored")


def cmd_reset(a):
    require_root()
    with locked(a.state_dir):
        delete_tables()
        with contextlib.suppress(FileNotFoundError):
            os.unlink(state_path(a.state_dir))
        print("all vmfw rules and state removed")


def fmt_age(ts):
    if not ts:
        return "never"
    d = int(time.time()) - ts
    return "%ds ago" % d if d < 120 else "%dm ago" % (d // 60) if d < 7200 else "%dh ago" % (d // 3600)


def cmd_status(a):
    st = load_state(a.state_dir)
    if not st:
        print("nothing applied")
        return
    s = st["config"]
    print("config:    %s" % (st.get("applied_from") or "(none; block/isolate stub)"))
    print("default:   %s (entries are %s)   interface: %s"
          % (s["default"], "ALLOWED" if s["default"] == "block" else "BLOCKED",
             s["bridge"]))
    lock = {"internet": "BLOCKED", "all": "ISOLATED (tap %s)" % st.get("isolate_tap")}
    print("lockdown:  %s" % lock.get(st.get("killswitch"), "off"))
    for e in st["entries"] + st["dynamic"]:
        print("  %-8s %-34s %s  [%s]" % (
            e["source"], entry_text(e),
            ", ".join(e["addrs"]) or ("(IPs learned via DNS)" if e["kind"] == "wild" else "(unresolved)"),
            fmt_age(e["resolved_at"]) if e["kind"] == "host" else
            "dns" if e["kind"] == "wild" else "literal"))


def cmd_counters(a):
    def table(family):
        return subprocess.run([nft_bin(), "list", "table", family, TABLE],
                              capture_output=True, text=True)
    p = table("inet")
    if p.returncode != 0:
        raise FwError("table inet %s not loaded: %s" % (TABLE, p.stderr.strip()))
    sys.stdout.write(p.stdout)
    p = table("bridge")  # only exists while isolated
    if p.returncode == 0:
        sys.stdout.write(p.stdout)


def cmd_print(a):
    st = need_state(a.state_dir)
    sys.stdout.write(render(st))
    if st.get("killswitch") == "all":
        sys.stdout.write(render_bridge_isolate(st))


def build_parser():
    p = argparse.ArgumentParser(
        prog="vmfw.py",
        description="nftables egress firewall for a MicroVM (IPv4 address/port based).")
    p.add_argument("--state-dir", default=os.environ.get("VMFW_STATE_DIR", DEFAULT_STATE_DIR),
                   help="where runtime state is kept (default %(default)s; "
                        "env VMFW_STATE_DIR)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("apply", help="load a JSON config and (re)build the firewall")
    s.add_argument("-c", "--config", default=os.path.join(SCRIPT_DIR, "vmfw.json"))
    s.add_argument("-n", "--dry-run", action="store_true",
                   help="resolve + print the ruleset; change nothing, no root needed")
    s.add_argument("--check", action="store_true", help="validate with `nft -c`, change nothing")
    s.add_argument("--strict", action="store_true", help="fail if any hostname cannot be resolved")
    s.add_argument("--reset-dynamic", action="store_true",
                   help="also forget entries added with `add`")
    s.set_defaults(fn=cmd_apply)

    s = sub.add_parser("add", help="dynamically add address(es)/URL(s) (allowed or blocked, per `default`)")
    s.add_argument("specs", nargs="+", metavar="SPEC")
    s.add_argument("-p", "--ports", help="e.g. 443 or 80,443,8000-8100")
    s.add_argument("--proto", choices=["tcp", "udp", "icmp"])
    s.add_argument("--comment")
    s.set_defaults(fn=cmd_add)

    s = sub.add_parser("remove", help="remove dynamically added entries (bare host removes all its ports)")
    s.add_argument("specs", nargs="+", metavar="SPEC")
    s.set_defaults(fn=cmd_remove)

    sub.add_parser("block", help="block the VM's internet access entirely (host access kept)"
                   ).set_defaults(fn=cmd_block)
    s = sub.add_parser("isolate", help="block ALL traffic from/to the VM's tap, incl. host access (ssh dies)")
    s.add_argument("tap", help="the VM's tap interface on the bridge, e.g. tap-microvm")
    s.set_defaults(fn=cmd_isolate)
    sub.add_parser("unblock", help="lift block/isolate, restore the configured rules"
                   ).set_defaults(fn=cmd_unblock)
    sub.add_parser("reset", help="remove all rules and state").set_defaults(fn=cmd_reset)
    sub.add_parser("status", help="show config, lockdown state, entries and resolved addresses"
                   ).set_defaults(fn=cmd_status)
    sub.add_parser("counters", help="show the live nft table with per-rule packet counters"
                   ).set_defaults(fn=cmd_counters)
    sub.add_parser("print", help="print the ruleset for the current state").set_defaults(fn=cmd_print)
    return p


def main():
    argv = sys.argv[1:] or ["apply"]  # no arguments: apply vmfw.json
    a = build_parser().parse_args(argv)
    try:
        a.fn(a)
    except FwError as e:
        print("error: %s" % e, file=sys.stderr)
        return 1
    except PermissionError as e:
        print("error: %s (try sudo)" % e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
