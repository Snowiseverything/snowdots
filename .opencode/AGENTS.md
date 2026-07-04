# AGENTS.md - System Context for "Freezer" (Personal Workstation)

## System
- **OS:** CachyOS x86_64 (Arch-based)
- **Hostname:** Freezer (192.168.0.111)
- **Desktop:** Hyprland + Wayland
- **Shell:** Fish + Starship
- **Editor:** `nano` only (do not use `micro`)
- **AI:** Ollama (NVIDIA CUDA) running locally, accessible via LAN
- **GPU:** NVIDIA RTX 4070 SUPER 12GB, driver 610.43.02
- **Kernel:** 7.1.2-1-cachyos-bore
- **Network:** enp6s0 (e8:9c:25:df:0d:e7) — 192.168.0.111/24
- **DNS:** systemd-resolved → Pi-Hole on Snowpi (192.168.1.35 / 100.83.33.67) + Tailscale MagicDNS (100.100.100.100)
- **WoL:** Enabled via udev rule (81-wol.rules — `wol g`) on enp6s0

## Storage
```
/dev/sda (931.5G external SSD)
├── sda1: 650G → /mnt/games (ext4, also used for ollama models)
├── sda2: 100G → /mnt/backups (btrfs)
└── sda3: ~181.5G → /mnt/data (btrfs, extra storage)
```

## Active Projects (~/Projects/)

### borsay-qallat (most active)
- **Stack:** Supabase + Expo/React Native (mobile) + React/Vite + TypeScript (web)
- **Docker:** Local supabase stack (auth, db, storage, realtime, etc.) via docker compose
- **Status:** Active development — fixing onboarding, language persistence, scrolling issues

### csgo-skins / dash-bot
- CS:GO skin showcase (PHP) + Discord economy bot (Node.js)
- Shared repo, dash-bot added recently

### enter-the-wired
- Game modding tools (accela mods, Steam tools)

### odysseus (stopped)
- Self-hosted AI workspace fork (was running via Docker, now stopped)
- **Upstream:** github.com/pewdiepie-archdaemon/odysseus

### commit-message-skill
- OpenCode skill for generating commit messages

### Other projects
- **ClapFinder** — Android skill finder app (Gradle/Kotlin)
- **linux-discord-rich-presence** — Discord RPC for Linux
- **MAD-68-custom-animation** — Web tool for MAD68 keyboard RGB animations
- **terminal-rain-lightning** — Terminal rain + lightning effect
- **pi-dashboard** — Flask dashboard for Snowpi (RPi4)
- **n8n** — n8n workflow automation (runs on Snowpi)
- **maptoposter** — Map poster generator
- **linux-wallpaperengine** — Wallpaper Engine for Linux
- **attack-shark-x11-driver** — Attack Shark mouse X11 config

## Key Scripts (in /home/snow/scripts/)
- `setup-ollama.sh` - Install ollama-cuda, store models at `/mnt/games/ollama`
- `resize-sda.sh` - Re-partition /dev/sda (unmounts before modifying)
- `dot-mirror.sh` - Sync Dotfiles to external backup
- `snow-audit.sh` - System audit
- `toggle-adult-block.sh` - Toggle StevenBlack adult blocklist on/off via /etc/hosts (Super+Shift+A)
- `cache-adult-blocklist.sh` - Cache adult blocklist from GitHub (daily timer)

## Ollama
```bash
sudo systemctl enable --now ollama
ollama run llama3
```

## Constraints
- **No sudo via OpenCode:** Password prompts fail. Run scripts as user, sudo commands manually.
- **Partition ops:** resize-sda.sh unmounts drives before modifying. Run manually.
- **No micro editor:** Use nano only.

## Services
- **Docker:** 10 containers (supabase stack + docker-studio + kong). Compose: `~/Projects/borsay-qallat/supabase/docker/docker-compose.yml`. Networks: docker_default (bridge).
- **Docker commands:** `docker ps`, `docker compose -p docker up -d` (for supabase/kong/studio stack)
- **Systemd:** `systemctl status/start/restart <service>`
- **Key active services:** tailscaled, iwd (wireless), docker, containerd, libvirtd, lactd, coolercontrold, sshd, sddm, nvidia-persistenced, smartd
- **WiFi:** iwd (not wpa_supplicant)
- **Bluetooth:** bluetooth.service + bluez

## Network
- **Main PC (Freezer):** 192.168.0.111/24, enp6s0 (MAC: e8:9c:25:df:0d:e7), WoL enabled
- **Snowpi (RPi4, DietPi):** 192.168.1.35 (Tailscale: 100.83.33.67)
- **Tailscale:** tailscaled service, 100.x.x.x range
- **DNS:** systemd-resolved (NetworkManager dns=systemd-resolved). Per-link DNS on enp6s0: 192.168.1.35 + 100.83.33.67 (both = Pi-Hole on Snowpi). Tailscale MagicDNS: 100.100.100.100 for tailnet hostnames
- **WiFi:** iwd (wireless service)
- **Virtual:** virbr0 (libvirt), docker bridge networks

## Dotfiles
Bare git repo at `~/.dotfiles`. Managed via scripts in `/home/snow/scripts/`.

## Backup & Restore Strategy

### Sync chain
- `dotsync` → git push GitLab → runs `dot-mirror.sh` → rsyncs to Snowpi
- `boot-sync` (systemd timer) → runs dotsync → rsyncs session DB to Snowpi

### What's backed up
| Data | GitLab | Snowpi | Local |
|------|:---:|:---:|:---:|
| Dotfiles | ✅ | ✅ | ✅ |
| AGENTS.md + MEMORY.md | ✅ | ✅ | ✅ |
| Session DB | ❌ | ✅ | ✅ |
| Projects | ❌ | ✅ | ✅ |
| Root configs | ❌ | ✅ | ✅ |
| SSH keys | ❌ | ❌ | ✅ |
| Wallpapers | ❌ | ❌ | ✅ |
| Package lists | ❌ | ✅ | ✅ |

### Full PC restore
1. Install CachyOS + base packages: `pacman -S --needed - < pkglist.txt`
2. `git clone git@gitlab.com:sn0wman/snowdots.git ~/Dotfiles`
3. Run `~/Dotfiles/scripts/dotsync` to populate `~/.opencode/` + restore configs
4. Restore SSH, wallpapers, projects from local mirror: `~/scripts/restore-dots.sh`
5. Pull session DB from Snowpi: `rsync snow@100.83.33.67:/mnt/backups/freezer-mirror/opencode-db-backup/opencode.db ~/.local/share/opencode/`

## Memory System (CRITICAL)
**AT START OF EVERY SESSION:** Read `~/.opencode/MEMORY.md` first.

**AFTER EVERY MESSAGE:** If Snow shares preferences, decisions, or important info:
- Ask: "Should I save this to memory?"
- Or proactively update `~/.opencode/MEMORY.md`

**Quick save:** `~/bin/mem "thing to remember"`

## User: Snow
- Prefers: nano editor, fish shell, Hyprland/Wayland
- Wants: Concise responses, ask before changes, plan before coding
- Accesses AI via: Telegram @Snowcodebot, OpenCode CLI

## Communication Style: Smart Caveman
Cut filler. Keep technical substance.

- Drop articles: a, an, the
- Drop filler: just, really, basically, actually
- Drop pleasantries, hedging, apologetic tone
- Fragments fine. Short synonyms.
- Technical terms stay exact. Code blocks unchanged.
- Pattern: [thing] [action] [reason]. [next step].

Example: "Model free. $0.02 spent = usage tracker artifact, not real charge."