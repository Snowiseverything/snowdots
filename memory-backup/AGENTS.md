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
- `scriptcat-mgr` — CLI for ScriptCat userscripts in Brave via LevelDB
- `fade-rgb.py` — Crossfade OpenRGB + MAD68 + Govee

## Network

- **Freezer:** 192.168.0.111/24, enp6s0
- **Snowpi (RPi4, DietPi):** 192.168.1.35 (Tailscale: 100.83.33.67)
- **Tailscale:** tailscaled, 100.x.x.x range
- **DNS:** systemd-resolved → Pi-Hole on Snowpi

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
- Config: `~/.pi/web-search.json` (`{"provider": "anysearch"}`)
- MCP server added to `~/.pi/agent/mcp.json`
- Full content returned inline with search (no separate extract call)
- Supports 17+ vertical domains: finance, academic, code, legal, health, etc.
- Batch search: up to 5 queries in one call
- Anonymous access works; API key = higher rate limits

## Constraints

- No sudo via agent: Password prompts fail. Run as user, sudo manually.
- No micro editor: Use nano only.
- **Commit discipline:** Never commit on Snow's behalf. Verify changes work first (reload/restart service), then ask Snow for approval. Commit messages follow `snow-commit` skill format: `area: imperative description`.

## Memory System (Pi Local)

**Location:** `~/.pi/MEMORY.md` and `~/.pi/AGENTS.md` (this file)

**Memory Hierarchy (read order):**

1. Global: `~/.opencode/MEMORY.md` + `~/.opencode/AGENTS.md` (shared with OpenCode)
2. Project-local: `PWD/MEMORY.md` + `PWD/AGENTS.md` (if both exist)
3. Session: `~/.pi/MEMORY.md` (Pi-specific session log)

**At session start:**

- Read `~/.opencode/MEMORY.md` first (global decisions)
- Read `~/.pi/MEMORY.md` (Pi-specific history)
- If in a project with both MEMORY.md + AGENTS.md → read project files too

**After every significant decision:**

- Ask: "Should I save this to memory?"
- Or proactively update `~/.pi/MEMORY.md`

**Quick save (fish):**

```fish
mem "thing to remember"          # writes to nearest project MEMORY.md
mem "thing" --global              # force write to ~/.opencode/MEMORY.md
```

**Fish shell:** No heredocs (`<<`). Use `echo '...' | sudo tee` instead.

## Sync

Sync to Snowpi + external backup via `boot-sync.sh` (user timer, once at boot) + user timers: `projects-sync` (5 min), `snowpi-backup-pull` (2 h), `backup-snowpi` (Sun 03:00 weekly). `dot-mirror.sh` mirrors Dotfiles/root configs/Projects → `/mnt/backups` + Snowpi.

## Skill usage (preferences)

- Default to `mp-*` (mattpocock/skills, ~/.agents/skills) for: tdd, code-review, diagnosing-bugs, research, handoff, to-spec/to-tickets, grill-me, wayfinder
- Keep `snow-commit` for commit messages (area: imperative, multi-remote)
- Keep `ui-ux-audit` for UI/UX design reviews (no mp-* equivalent)
