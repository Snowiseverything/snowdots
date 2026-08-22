# Snowpi Architecture

> RPi4 home server. Companion doc to `Freezer PC/architecture.md`.
> Snow DSM 4 (DietPi-based, Debian), headless.

## System Overview

| Component     | Detail                                                                    |
| ------------- | ------------------------------------------------------------------------- |
| **Hardware**  | Raspberry Pi 4 Model B Rev 1.4 (aarch64), 8GB (3.9G free/used pool)       |
| **OS**        | Debian 12 (via DietPi), kernel `6.18.39+rpt-rpi-v8`                       |
| **Storage**   | 64GB SD (/dev/mmcblk0), root 57G @ 50%; log2ram (128M tmpfs for /var/log) |
| **Network**   | 192.168.1.35/24 LAN, Tailscale 100.83.33.67 (offers exit node)            |
| **Shell**     | fish + starship (SSH default) — ⚠️ no bash loops inline, use scripts      |
| **DNS chain** | FTL (Pi-hole) on :53 → Unbound validating resolver on :5335               |
| **User**      | `snow` (UID 1001), sudo via password                                      |

---

## 1. Services Inventory (systemctl running)

| Service                                       | Purpose                                 |
| --------------------------------------------- | --------------------------------------- |
| `pihole-FTL`                                  | DNS sinkhole, dnsmasq, web UI on :8080  |
| `unbound`                                     | Validating recursive resolver on :5335  |
| `docker` + `containerd`                       | Container runtime (see §2)              |
| `tailscaled`                                  | Tailscale node, offers exit node        |
| `ssh`                                         | OpenBSD SSH server                      |
| `syncthing@snow`                              | File sync (WebUI :8384, relay :22000)   |
| `snowpi-monitor`                              | Python proxy dashboard on :5050 (§4)    |
| `chrony`                                      | NTP client/server (fix for no RTC)      |
| `iperf3`                                      | Network throughput test server on :5201 |
| `bluetooth`, `cron`, `dbus`, `NetworkManager` | base                                    |
| `unattended-upgrades`                         | auto security updates                   |

notable: `rpcbind`/`nfs-blkmap`/`udisks2` (NFS+disk helpers), `getty@tty1` + `serial-getty@ttyS0`.

---

## 2. Docker Compose Projects

All in `~/` on Snowpi. `docker compose ls` projects:

| Project                                   | Compose file                          | Containers / role                                         |
| ----------------------------------------- | ------------------------------------- | --------------------------------------------------------- |
| `ideon`                                   | `~/ideon/docker-compose.yml`          | `ideon-app` (:3030) + `ideon-db` (postgres:18) — app + DB |
| `homepage`                                | `~/homepage/docker-compose.yml`       | homepage (gethomepage) — main dash                        |
| `glance`                                  | `~/monitoring/glance/...`             | glance (:8082) — quick glance widget                      |
| `monitoring`                              | `~/monitoring/docker-compose.yml`     | uptime-kuma, glance — monitoring                          |
| `freshrss`                                | `~/freshrss/...`                      | freshrss (:8083) — RSS reader                             |
| `dagu`                                    | `~/dagu/...`                          | dagu (:8084) — workflow engine                            |
| `filebrowser`                             | `~/filebrowser/...`                   | caddy (reverse proxy) + rustyfile/filebrowser (:8081)     |
| `fast-note-sync`                          | `~/fast-note-sync/...`                | fast-note-sync-service (:9000)                            |
| `iot-stack`                               | `~/iot-stack/...`                     | homeassistant (HA) + smtp-proxy (:1025)                   |
| `n8n`, `notesnook`, `boxbox`, `rustyfile` | compose files present (status varies) |

**Full container list (`docker ps`):** ideon-app, ideon-db, homeassistant, openclaw (:18789), rustyfile (:8081, currently unhealthy), dagu (:8084), smtp-proxy (:1025), freshrss (:8083), homepage, glance (:8082), caddy, fast-note-sync-service (:9000), uptime-kuma.

---

## 3. Reverse Proxy (Caddy)

Caddy in the `filebrowser` stack. Config: `~/filebrowser/Caddyfile`.
Reload: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`.
Internal TLS everywhere (`tls internal`). **VHost map** (all `*.snowpi` → internal services):

| Host            | Upstream               | Role                                       |
| --------------- | ---------------------- | ------------------------------------------ |
| `pihole.snowpi` | localhost:8080         | Pi-hole web UI                             |
| `snowpi`        | localhost:3000 / :8080 | Homepage dash + Pi-hole `/admin/*` routing |
| `files.snowpi`  | localhost:8081         | filebrowser                                |
| `ha.snowpi`     | 127.0.0.1:8123         | Home Assistant                             |
| `status.snowpi` | localhost:3001         | status dashboard                           |
| `rss.snowpi`    | localhost:8083         | FreshRSS                                   |
| `glance.snowpi` | localhost:8082         | Glance                                     |
| `ideon.snowpi`  | localhost:3030         | Ideon app (gzip zstd)                      |
| `dagu.snowpi`   | localhost:8084         | Dagu workflows                             |
| `claw.snowpi`   | 127.0.0.1:18789        | OpenClaw (with forwarding headers)         |

---

## 4. DNS Chain: Pi-hole → Unbound (DNSSEC)

The core of Snowpi's network role.

```
Clients (Freezer, LAN, Tailscale)
        │  :53
        ▼
Pi-hole FTL (pihole-FTL, dnsmasq)
   blocking + web UI :8080
        │  forwarder → 127.0.0.1:5335
        ▼
Unbound (validating recursive resolver)
   :5335, DNSSEC validation ON (root-auto-trust-anchor-file)
        │
        ▼
root servers → TLD → authoritative
```

### Config files

- **Pi-hole TOML**: `/etc/pihole/pihole.toml` (`dnssec` toggle lives under the resolver block; **must stay `false`** — see below)
- **Pi-hole setup**: `/etc/pihole/setupVars.conf`
- **Unbound**: `/etc/unbound/unbound.conf` with `include-toplevel: /etc/unbound/unbound.conf.d/*.conf`:
  - `pi-hole.conf` — interface `127.0.0.1`, port `5335`, thread/cache tuning
  - `99-local.conf` — **deterministic override, loaded last**: hardening (harden-referral-path, qname-minimisation-strict, use-caps-for-id), big caches (msg 256m / rrset 512m), `cache-min-ttl: 600`, `serve-expired: yes`, `aggressive-nsec: yes`
  - `root-auto-trust-anchor-file.conf` — the DNSSEC root trust anchor
  - `dietpi.conf` — DietPi baseline (overridden by 99-local)
  - `remote-control.conf` — unbound-control via `/run/unbound.ctl`

### ❗ DNSSEC rule — validate ONCE, at Unbound, not in FTL

**Unbound does the DNSSEC validation** (it's the recursive, validating resolver — the correct single place). FTL (dnsmasq) must **not** second-validate.

- `/etc/pihole/pihole.toml` → `dnssec = false` (validator off in FTL)
- `/etc/pihole/dnsmasq.conf` → `dnssec` line commented out (was toggled on manually; remove)

Enable/disable DNSSEC properly: `sudo pihole -a dnssec` (toggling it in the web/CLI) and restart FTL.

---

## 5. What DNSSEC is and why it mattered (2026-08)

### What it does

Authenticates DNS answers (does **not** encrypt). Zone owner signs records (RRSIG) with a private key; resolvers verify a chain of trust rooted at the DNS root (root KSK → TLD DS → domain DNSKEY → RRSIG).

Protects against:

- **Cache poisoning / spoofing** (Kaminsky-class) — forged A/AAAA hijacking traffic
- **MITM redirection** — attacker answering "google.com = evil-IP"
- **Authenticated denial** — NSEC/NSEC3 proves a domain doesn't exist
- Secondary records too: MX, TXT/SPF/DKIM

### Why double-validation slowed things down

The setup was validating **twice** (FTL's dnsmasq `dnssec` flag + Unbound already validating):

1. **Extra lookups on cache miss** — validator must assemble chain of trust: query TLD DS, fetch parent DNSKEYs, verify RRSIG. Cold queries pay 1–3 extra round trips.
2. **Bigger responses** — RRSIG/DNSKEY/NSEC inflate replies, often crossing the UDP 4096B limit → **TCP fallback** (full handshake added per uncached name).
3. **CPU crypto cost** — RSA/ECDSA signature verification per record set. Measurable on an RPi4 under load.
4. **Nothing served until validated** — even root/TLD key fetches must complete first.
5. **Failures = SERVFAIL storms** — dnsmasq DNSSEC integration is fragile: clock skew (RPi has **no RTC** — before NTP syncs, signatures verify as expired), broken zones, stale key cache → browsers retry 2–3× → looks like "slow searches" (actually failed).

### Bottom line

Keep DNSSEC at **one** layer. Unbound does it correctly at the recursion boundary — the right place. FTL re-validating is pure overhead + a failure point. Disabling FTL DNSSEC loses **no** protection; Unbound still validates. (If you ever drop Unbound for plain forwarding, let the upstream resolver validate and keep FTL validation off.)

### Verify post-fix

```
dig @192.168.1.35 google.com        # → status: NOERROR, ~15ms
```

---

## 6. snowpi-monitor (dashboard proxy, :5050)

Systemd unit `snowpi-monitor.service`: `python3 /home/snow/snowpi-monitor/proxy.py`.

- Python HTTP server (http.server) + Docker Unix-socket API wrapper
- Reads `/home/snow/snowpi-monitor/.env` for OpenRouter key + ntfy topic
- Serves static dashboard from `snowpi-monitor/static/`
- Optional LLM analysis hook (OpenRouter, default `meta-llama/llama-3.3-70b-instruct:free`), ntfy alerts
- Restart on-failure, sec=10, User=snow

---

## 7. Port Map (ss -tlnp)

| Port  | Service               | Bind                                        |
| ----- | --------------------- | ------------------------------------------- |
| 22    | ssh                   | 0.0.0.0                                     |
| 53    | pihole-FTL            | 0.0.0.0                                     |
| 111   | rpcbind               | 0.0.0.0                                     |
| 5050  | snowpi-monitor        | 0.0.0.0                                     |
| 5201  | iperf3                | \*                                          |
| 5335  | unbound               | 127.0.0.1                                   |
| 8123  | homeassistant         | 192.168.1.35 (incl. Tailscale 100.83.33.67) |
| 8080  | Pi-hole web           | 0.0.0.0                                     |
| 8081  | rustyfile/filebrowser | 0.0.0.0                                     |
| 8082  | glance                | 0.0.0.0                                     |
| 8083  | freshrss              | 0.0.0.0                                     |
| 8084  | dagu                  | 0.0.0.0                                     |
| 9000  | fast-note-sync        | 0.0.0.0                                     |
| 18789 | openclaw              | 0.0.0.0                                     |
| 3030  | ideon-app             | 0.0.0.0                                     |
| 8384  | syncthing WebUI       | 127.0.0.1                                   |
| 2019  | caddy internal API    | 127.0.0.1                                   |
| 22000 | syncthing relay       | \*                                          |

---

## 8. Tailscale Mesh

```
100.83.33.67     snowpi        (this host — idle, offers exit node)
100.87.27.79     freezer       active · direct 192.168.0.111:41641
100.98.128.106   snow-phone    active · direct 192.168.1.66
100.76.20.45     hamood123     offline
100.79.85.11     imans-ipad    offline
100.104.132.122  imans-macbook-air offline
100.97.131.64    snow-pc       offline (Windows)
```

Access from Freezer: `ssh snow@100.83.33.67`. If it hangs, `tailscale ping 100.83.33.67` first.

---

## 9. Notes & Gotchas

- **fish default shell on SSH**: inline `for` loops / `$var` in `ssh "..."` break (`$` and `for` are fish-invalid). **Use a script via `bash /tmp/script.sh`** or `ssh 'bash -s'` — not bare inline bash.
- **No RTC**: time comes from chrony/NTP after boot. Causes DNSSEC validation failure for a window before NTP sync (pre-2026-08 fix).
- **log2ram**: /var/log on 128M tmpfs (2.4M used) — logs lost on reboot by design.
- **slow Docker pulls historically**: undervoltage. Fixed via `/boot/firmware/config.txt` (`avoid_pwm_underflow=1`, `usb_max_current=1`); `vcgencmd get_throttled` should read `0x0`.
- **homeassistant** served via `ha.snowpi` (caddy) + direct `:8123`.
- **rustyfile** container currently reported `unhealthy` — likely needs a HA/filebrowser healthcheck check.
