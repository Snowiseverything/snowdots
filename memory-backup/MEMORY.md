# Session Memory

## 2026-06-17: Complete Snowpi Monitor Overhaul

### Decision Tree

1. **Problem**: Browser forces HTTPS on `snowpi:5050`
   - **Options**: (a) Self-signed cert in proxy, (b) Caddy reverse proxy
   - **Chosen**: Caddy reverse proxy → `monitor.snowpi` (consistent with existing subdomain pattern)

2. **Problem**: Single-threaded proxy blocks on LLM analysis
   - **Chosen**: `socketserver.ThreadingMixIn` for concurrent requests

3. **Problem**: Docker API uses chunked transfer encoding
   - **Chosen**: Parse chunks in `docker_api()` function

4. **Dashboard direction**: Replace custom HTML with Homepage
   - **Reason**: Professional, feature-rich, auto-detects Docker containers
   - **Integration**: Homepage at `snowpi/`, monitor API at `monitor.snowpi`
   - **OpenCode**: Embedded via widget iframe on Homepage

5. **Pi-hole v6 conflict**: Uses `/api/*` paths that clash with Homepage
   - **Chosen**: Move Pi-hole to `pihole.snowpi` subdomain

### Architecture

- `snowpi/` → Homepage (port 3003) ← Docker socket for container auto-detection
- `monitor.snowpi` → Proxy (port 5050) ← OpenCode CLI for LLM analysis
- `pihole.snowpi` → Pi-hole (port 8089)
- `files.snowpi` → Filebrowser (port 8080)
- `ha.snowpi` → Home Assistant (port 8123)
- `status.snowpi` → Uptime Kuma (port 3001)

### Files on Snowpi

- `~/snowpi-monitor/proxy.py` — HTTP API server (containers, system, LLM chat)
- `~/snowpi-monitor/monitor.py` — Active watchdog (auto-fix + OpenCode triage)
- `~/snowpi-monitor/static/` — Dashboard HTML + widget.html for Homepage embed
- `~/snowpi-monitor/.env` — Config (OpenRouter key optional)
- `~/filebrowser/Caddyfile` — Caddy reverse proxy config
- `~/homepage/config/` — Homepage YAML configs
- `~/.local/share/opencode/auth.json` — OpenCode auth (used by CLI)

## 2026-06-20: Service tweaks & Caddy routing fixes

### Changes

- **Caddy Auto HTTPS**: Changed `snowpi:80` → `http://snowpi:80` (and same for all rules) to prevent 308 redirect loop. Browsers cache 308s — clear cache if still redirecting.
- **Pi-hole port**: Moved from 8089 → **8080**. Updated Homepage services.yaml and Caddy routing.
- **Caddy routing**: Explicit hostname matching instead of catch-all `:80`:
  - `pi.hole`, `pihole.snowpi` → Pi-hole (`localhost:8080`)
  - `snowpi`, `snowpi.lan`, `192.168.1.35`, `100.83.33.67`, `localhost` → Homepage (`localhost:3000`)
  - `:11443` → Xbox Dev Portal over HTTPS (any hostname on port 11443)
- **BoxBox**: Username `admin` → `snow`, password `snowbox1781676671` → `snowbox`
- **Iraq Pay**: Stopped (port 3000) — `docker stop iraq-pay && docker rm iraq-pay`
- **Homepage networking**: Changed from bridge + `extra_hosts: host.docker.internal:192.168.1.35` to `network_mode: host` (port 3000). This fixes siteMonitors (services blocked by UFW on Docker bridge).
- **Homepage siteMonitors**: Updated from `host.docker.internal` to `127.0.0.1` because `localhost` inside container resolves to IPv6 `::1` which most services don't bind to.

### Architecture

- `snowpi/` → Caddy → Homepage (port 3000, host network)
- `pi.hole/admin/` → Caddy → Pi-hole (port 8080)
- `snowpi:11443` → Caddy → Xbox Dev Portal (`192.168.1.241:11443`, HTTPS with `tls_insecure_skip_verify`)
- Homepage icons load from `cdn.jsdelivr.net` (simple-icons) — allow in Pi-hole if icons missing

### Reminders

- Always `fuser -k 5050/tcp` before starting test proxy on Snowpi
- Always use `bash -c "..."` or SCP+Popen for remote commands (fish shell on Snowpi)
- OpenCode CLI: `/home/snow/.npm-global/bin/opencode` (set PATH in systemd units)
- `opencode run --format json --dangerously-skip-permissions` for non-interactive analysis

## 2026-08-01

- test in home dir

## 2026-08-01

- test in home dir

## 2026-08-01

- verify system works

## 2026-08-09 — skwd-wall paper engine + skwd-paper compat libs

- skwd-wall was using `awww` engine; switched to `skwd-paper` for shader transitions.
- `skwd-paper` binary needs FFmpeg 6.x libs: `libavutil.so.60`, `libavcodec.so.62`, `libavformat.so.62`, `libavdevice.so.62`, `libswscale.so.9`, `libswresample.so.6`.
- System only has FFmpeg 7.x/4.4; assembled compat libs from PCSX2/Steam Proton into `~/.local/lib/skwd-paper/`.
- Created wrapper `~/.local/bin/skwd-paper` with `LD_LIBRARY_PATH=/home/snow/.local/lib/skwd-paper`.
- Set `paper.engine = skwd-paper` + `paper.transition.enabled = true` in `~/.config/skwd-wall/config.json`.
- Wired daemon via systemd override: `~/.config/systemd/user/skwd-daemon.service.d/override.conf` with `SKWD_PAPER_BIN=/home/snow/.local/bin/skwd-paper`.
- Removed duplicate `skwd.service` and broken `/home/snow/shell.qml` test harness that was causing wall-ui launch failures.
- Verified: wall-ui launches with `/usr/share/skwd-wall/shell.qml`, 334 wallpapers loaded, transitions work from GUI.
