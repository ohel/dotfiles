# vmfw – nftables egress firewall for virtual machines

Runs **on the host**, as root. Python 3.8+, stdlib only, uses only `nft`.

All rules live in their own table `inet vm_fw` (plus `bridge vm_fw` only while
isolate is on). Host's `ip vm_nat` table is never touched. Every
change re-renders the whole ruleset from a state file and loads it atomically.

Yep, it's made by AI, for running AI in an isolated microVM.
Designed to work with my VM scripts and network setup.

## Quick start (on the host)

`sudo ./vmfw.py` applies default config file, `vmfw.json`. Change with -c.

    # 1. read the ruleset without changing anything (no root needed)
    ./vmfw.py apply --dry-run
    # 2. validate against the kernel, still changing nothing
    sudo ./vmfw.py apply --check
    # 3. for real ("apply" is optional)
    sudo ./vmfw.py apply

    sudo ./vmfw.py add example.org:443          # dynamic add (allowed/blocked per `default`)
    sudo ./vmfw.py remove example.org           # remove (all its ports)
    sudo ./vmfw.py status                       # config, lockdown state, entries + resolved IPs
    sudo ./vmfw.py counters                     # live nft table with per-rule packet counters
    sudo ./vmfw.py block                        # cut the VM's internet (host<->VM, ssh stay)
    sudo ./vmfw.py isolate tap-microvm          # block EVERYTHING from/to specified VM tap
    sudo ./vmfw.py unblock                      # lift block or isolate
    sudo ./vmfw.py reset                        # delete all rules + state

State is in `/tmp/vmfw/state.json` (override: `--state-dir`/`VMFW_STATE_DIR`);
it is refused unless the directory is a real directory owned by the current user
with mode 0700. Being in /tmp it is cleared on reboot, just like the rules, so
run `apply` again after the bridge is up. A reboot also forgets entries added
with `add` and any block/isolate; within a boot, `apply` keeps them.

## Config

* `interface` (default `vmbridge`): the bridge the VM is attached to. All rules
  match on it. The VM's tap name is only needed for `isolate TAP`.
* `default` (**required**): `"block"` or `"allow"`. It is the only thing that
  decides what `entries` mean: with `"block"` the entries are the **allow-list**,
  with `"allow"` they are the **block-list**. `add` follows the same rule.
* Entry forms (string or `{"host":..., "ports":[...], "proto":..., "comment":...}`):
  * `1.2.3.4`, `10.0.0.0/8`, `example.com` – all ports/protocols
  * `example.com:443`, `host:80,443,8000-8100` – ports (tcp+udp unless proto given)
  * `tcp:host:22`, `udp:1.2.3.4:53`, `icmp:host`
  * `*.example.com` – wildcard: subdomains only (not `example.com` itself, add that
    separately). Needs the DNS filter; see below.
  * `https://example.com/x` – host + implied port (http 80, https 443, ssh 22,
    ftp 21, ws 80, wss 443, git 9418) or the explicit port; tcp only.
    Use a bare hostname if you want *all* ports.
* Hostnames are resolved (IPv4 only) by the script at `apply` and `add`
  time. If a lookup fails the previous addresses are kept (`--strict` to fail instead).
* `subdomains` (default false): if true, a hostname entry `example.com` also
  matches `a.example.com`, `a.b.example.com`, ... (so `*.example.com` becomes
  unnecessary). Note that traffic to the subdomains' addresses is then allowed (or
  blocked) on `example.com`'s ports.
* `host_access` (optional): an allow-list of what the VM may reach *on the host
  itself* (e.g. 10.0.1.1); everything else there is blocked. Items are `icmp`,
  `tcp:PORTS`, `udp:PORTS` (e.g. `tcp:22`, `udp:67,68`, `tcp:8000-8100`), or `"*"`
  for everything. Default if omitted: `["icmp", "udp:67"]` (ping and DHCP). DNS (port
  53, where the DNS filter listens) is always open. `[]` closes the host completely
  (except DNS).
* `allow_ipv6` (default false): when false, all IPv6 from the VM is dropped
  (the filter is IPv4-only, so true means IPv6 is unfiltered).
* `log_blocked` (default false): log blocked packets to the kernel log (rate-limited).
* Blocked packets are silently dropped.

### Whitelist example

```json
{
  "interface": "vmbridge",
  "default": "block",
  "log_blocked": false,
  "subdomains": true,
  "host_access": ["icmp", "udp:67"],

  "entries": [
    "github.com",
    "registry.npmjs.org:443",
    { "host": "192.0.2.10", "ports": [22, "8000-8100"], "proto": "tcp", "comment": "build box" },
    "icmp:1.1.1.1",
    "udp:1.1.1.1:53"
  ]
}
```

### Blacklist example

`default: allow`: everything is permitted except what the entries block. This
one blocks private networks, one hostname, SMTP to a range, QUIC, and external DNS
(so the guest has to use the DNS filter):

```json
{
  "interface": "vmbridge",
  "default": "allow",
  "log_blocked": true,

  "entries": [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "169.254.0.0/16",
    "evil.example.com",
    "tcp:203.0.113.0/24:25",
    "udp:0.0.0.0/0:443",
    "udp:0.0.0.0/0:53",
    "tcp:0.0.0.0/0:53,853"
  ]
}
```

## DNS filter (`vmfw_dns.py`)

After `sudo ./vmfw.py apply`, leave running:

    sudo ./vmfw_dns.py

It listens (udp+tcp, port 53) on the IPv4 address of the bridge named by `interface`,
only answers clients from that subnet, and forwards to the nameservers in the host's
`/etc/resolv.conf` (or those given with `--upstream`). Point the guest's resolver at the bridge address (e.g. DHCP
option 6). The firewall has **no special DNS rules**: other DNS servers are
reachable or not purely by `default` and the entries, so the filter can be
bypassed unless you close that route yourself:

* `default: block`: external DNS is dropped like everything else. To allow a
  specific resolver, list it, e.g. `udp:1.1.1.1:53`.
* `default: allow`: any DNS works. To force the guest through the filter, block
  external DNS: `udp:0.0.0.0/0:53`, `tcp:0.0.0.0/0:53,853` (see
  the blacklist example above).

Port 53 *on the host* is always open to the guest (`host_in`).
Options: `--listen IP`, `--port`, `--upstream IP[:PORT]`.

* `default: block`: names matching no entry get NXDOMAIN. For a matching hostname
  or wildcard entry, the A records of the answer are added to that entry's nft
  set with a timeout (the answer's TTL, but at least an hour, see below) *before* the guest
  receives them, so the guest can reach exactly the addresses it was given, on
  the entry's ports. Addresses from `apply` (pre-resolution) stay as permanent
  members of the set. Non-global answers (private, loopback, link-local) are
  never opened (DNS rebinding protection) but are still passed on to the guest.
* `default: allow`: names matching an entry get NXDOMAIN; the rest is forwarded.
  DoH and hardcoded IPs bypass name filtering. Wildcards act on DNS only.
* Names match case-insensitively. Without `subdomains`, `example.com` matches
  only itself; `*.example.com` matches subdomains only. AAAA queries of allowed names are answered
  empty unless `allow_ipv6` is true.
* The daemon picks up `apply`/`add`/`remove` automatically (it watches the state
  file) and restores learned addresses after each reload. Restart it if `interface`
  changed.
* A timed-out address closes the door for long-lived connections that outlast it
  (every packet is checked), hence the one hour minimum (`MIN_TTL` in `vmfw_dns.py`).

## Notes / caveats

* Blocking takes effect immediately for existing connections too (every
  packet from the VM is evaluated; only host-input replies use conntrack).
* Learned DNS addresses live in the kernel sets, which every reload (`apply`, `add`,
  `remove`, `block`, `unblock`) empties. While `vmfw_dns.py` is running it notices
  the changed state file (within about half a second) and puts the still-valid
  addresses back, so in-flight connections only see a brief stall. If the daemon is
  not running or gets restarted, learned addresses are lost until the guest
  resolves the names again.
* Traffic between two VMs on the same bridge (L2-only) is not filtered.
* `isolate` also drops at the bridge layer on the tap you name (`isolate TAP`), in both directions
  (frames from the VM and frames delivered to it, incl. from other VMs on the bridge).
