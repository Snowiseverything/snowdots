# System Context — Freezer

## System

- **OS:** CachyOS x86_64 (Arch-based)
- **Hostname:** Freezer (192.168.0.111)
- **Desktop:** Hyprland + Wayland
- **Shell:** Fish + Starship
- **Editor:** `nano` only (do not use `micro`)
- **GPU:** NVIDIA RTX 4070 SUPER 12GB, driver 610.43.02
- **Kernel:** 7.1.3-2-cachyos-bore
- **Network:** enp6s0 — 192.168.0.111/24
- **DNS:** systemd-resolved → Pi-Hole on Snowpi (192.168.1.35 / 100.83.33.67) + Tailscale MagicDNS (100.100.100.100)
- **WoL:** Enabled via udev rule on enp6s0

## Storage

```
/dev/sda (931.5G external SSD)
├── sda1: 650G → /mnt/games (ext4, ollama models)
├── sda2: 100G → /mnt/backups (btrfs, compress=zstd:3)
└── sda3: ~181.5G → /mnt/data (btrfs, compress=zstd:3)
```

Rootfs btrfs: compress=zstd:1, ssd, space_cache=v2, noatime
`/mnt/data` at 98% — nearly full

## Active Projects

- **borsay-qallat** — Supabase + Expo/React Native + React/Vite + TS (most active)
- **csgo-skins / dash-bot** — PHP skin site + Discord economy bot
- **enter-the-wired** — Game modding (accela mods, Steam)
- **ClapFinder** — Android skill finder (Gradle/Kotlin)
- **MAD-68-custom-animation** — Web tool for MAD68 RGB
- **terminal-rain-lightning** — Terminal rain effect
- **pi-dashboard** — Flask on Snowpi
- **n8n** — Workflow automation on Snowpi
- **maptoposter** — Map poster generator
- **linux-wallpaperengine** — Wallpaper Engine for Linux
- **attack-shark-x11-driver** — Attack Shark mouse X11 config
- **opencode-discord-presence** — Discord RPC plugin for OC

## Key Scripts (~/scripts/)

- `dot-mirror.sh` — Sync Dotfiles to external backup
- `snow-audit.sh` — System audit
- `toggle-adult-block.sh` — Toggle StevenBlack porn blocklist
- `scriptcat-mgr` — CLI for ScriptCat userscripts in Brave
- `fade-rgb.py` — Crossfade OpenRGB + MAD68 + Govee

## Network

- **Freezer:** 192.168.0.111/24, enp6s0
- **Snowpi (RPi4, DietPi):** 192.168.1.35 (Tailscale: 100.83.33.67)
- **Tailscale:** tailscaled, 100.x.x.x range
- **DNS:** systemd-resolved → Pi-Hole on Snowpi

## Dotfiles

Dotfiles git repo at `~/Dotfiles` (regular repo, `main`). Remotes: GitHub (sn0wmann1/snowdots) + GitLab (sn0wman/snowdots) are **public — do NOT push without approval**. Local-only sync target: `snowpi` remote → bare repo `snow@100.83.33.67:/home/snow/git-vault/Dotfiles.git`. Managed via `~/scripts/dotsync`.

## Reference Docs (architecture)

When stuck on either machine or need service/architecture reference, **check the Obsidian vault docs before re-discovering**:

- **Freezer**: `~/Dotfiles/docs/Freezer PC/architecture.md`
- **Snowpi**: `~/Dotfiles/docs/Snowpi/architecture.md` (added 2026-08-22 — services, compose projects, Caddy vhosts, DNS chain, ports, Tailscale mesh, gotchas, and full DNSSEC writeup)
- Both in the `~/Dotfiles/docs/` Obsidian vault. These are the canonical machine references.

Key Snowpi facts to remember:

- RPi4, Debian (DietPi), headless. LAN 192.168.1.35 / Tailscale 100.83.33.67
- **DNS chain**: FTL (Pi-hole) :53 → Unbound validating :5335. **DNSSEC validates ONCE at Unbound; FTL `dnssec` must stay `false`** (double-validation caused slow/failing lookups, fixed 2026-08)
- SSH: `ssh snow@100.83.33.67`. **Snowpi default shell is fish — no inline bash `for`/`$var` in ssh strings; use a script via `bash /tmp/x.sh`**

## Services

- Docker: 10 containers (supabase + studio + kong) at `~/Projects/borsay-qallat/supabase/docker/docker-compose.yml`
- Key services: tailscaled, iwd, docker, containerd, libvirtd, lactd, coolercontrold, sshd, sddm
- Bluetooth: bluetooth.service + bluez

## User: Snow

- Prefers: nano editor, fish shell, Hyprland/Wayland
- Access AI via: Telegram @Snowcodebot, OpenCode CLI, Pi Agent

## Communication Style

Cut filler. Keep technical substance.

- Drop articles, filler words, pleasantries, hedging
- Fragments fine. Short synonyms.
- Technical terms stay exact. Code blocks unchanged.

## Web Search

- **Provider:** AnySearch — 1,000 free req/day, no CC needed
- Config: `~/.pi/web-search.json` (\`{"provider": "anysearch"}\`)
- MCP server added to `~/.pi/agent/mcp.json`
- Full content returned inline with search (no separate extract call)
- Supports 17+ vertical domains: finance, academic, code, legal, health, etc.
- Batch search: up to 5 queries in one call
- Anonymous access works; API key = higher rate limits

## Constraints

- No sudo via agent: Password prompts fail. Run as user, sudo manually.
- No micro editor: Use nano only.
