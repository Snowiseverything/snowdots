# AGENTS.md - System Context for "Freezer" (Personal Workstation)

## System
- **OS:** CachyOS x86_64 (Arch-based)
- **Hostname:** Freezer (192.168.0.111)
- **Desktop:** Hyprland + Wayland
- **Shell:** Fish + Starship
- **Editor:** `nano` only (do not use `micro`)
- **AI:** Ollama (NVIDIA CUDA) running locally via LAN
- **GPU:** NVIDIA RTX 4070 SUPER 12GB, driver 610.43.02
- **Kernel:** 7.1.3-2-cachyos-bore
- **Network:** enp6s0 (e8:9c:25:df:0d:e7) — 192.168.0.111/24
- **DNS:** systemd-resolved → Pi-Hole on Snowpi (192.168.1.35 / 100.83.33.67) + Tailscale MagicDNS (100.100.100.100)
- **WoL:** Enabled via udev rule (81-wol.rules — `wol g`) on enp6s0

## Storage
```
/dev/sda (931.5G external SSD)
├── sda1: 650G → /mnt/games (ext4, ollama models)
├── sda2: 100G → /mnt/backups (btrfs, compress=zstd:3, discard=async)
└── sda3: ~181.5G → /mnt/data (btrfs, compress=zstd:3, discard=async)
```
- **Rootfs** btrfs: compress=zstd:1, ssd, space_cache=v2, noatime
- **/home** btrfs LUKS: compress=zstd:1, ssd, noatime
- **fstrim.timer** enabled weekly
- `/mnt/data` at 98% — nearly full

## Active Projects
- **borsay-qallat** — Supabase + Expo/React Native + React/Vite + TS (most active)
- **csgo-skins** / **dash-bot** — PHP skin site + Discord economy bot
- **enter-the-wired** — Game modding (accela mods, Steam)
- **commit-message-skill** — OpenCode skill for commit messages
- **ClapFinder** — Android skill finder (Gradle/Kotlin)
- **linux-discord-rich-presence** — Discord RPC
- **MAD-68-custom-animation** — Web tool for MAD68 RGB
- **terminal-rain-lightning** — Terminal rain effect
- **pi-dashboard** — Flask on Snowpi
- **n8n** — Workflow automation on Snowpi
- **maptoposter** — Map poster generator
- **linux-wallpaperengine** — Wallpaper Engine for Linux
- **attack-shark-x11-driver** — Attack Shark mouse X11 config
- **opencode-discord-presence** — Discord RPC plugin for OC

## Key Scripts (~/scripts/)
- `setup-ollama.sh` — Install ollama-cuda, models at `/mnt/games/ollama`
- `resize-sda.sh` — Re-partition /dev/sda (unmounts first)
- `dot-mirror.sh` — Sync Dotfiles to external backup
- `snow-audit.sh` — System audit
- `toggle-adult-block.sh` — Toggle StevenBlack porn blocklist (Super+Shift+A)
- `cache-adult-blocklist.sh` — Cache blocklist from GitHub (daily)
- `opencode-switch` — Session switcher: list all OC sessions, pick by number, resume
- `boot-sync.sh` — Boot-time sync: pushes session DB + config to Snowpi
- `setup-oc-sync.sh` — Symlink shared OC configs into `~/.opencode/`

## OpenCode Session Management
- All sessions stored in `~/.local/share/opencode/opencode.db`
- Sessions visible from any directory via `global` project
- **Session switcher:** `~/scripts/opencode-switch` — list 83 sessions, pick by number, auto-resume
- **Quick resume:** `opencode -s <session_id>`
- **With --mini flag:** `opencode -s <session_id> --mini` for lightweight TUI
- Sessions auto-sync to Snowpi via `boot-sync.sh` timer

## Ollama
```bash
sudo systemctl enable --now ollama
ollama run llama3
```

## Constraints
- **No sudo via OpenCode:** Password prompts fail. Run as user, sudo manually.
- **Partition ops:** resize-sda.sh unmounts before modifying. Run manually.
- **No micro editor:** Use nano only.

## Services
- **Docker:** 10 containers (supabase + studio + kong). Compose: `~/Projects/borsay-qallat/supabase/docker/docker-compose.yml`
- **Docker commands:** `docker ps`, `docker compose -p docker up -d`
- **Systemd:** `systemctl status/start/restart <service>`
- **Key services:** tailscaled, iwd, docker, containerd, libvirtd, lactd, coolercontrold, sshd, sddm, nvidia-persistenced, smartd
- **WiFi:** iwd (not wpa_supplicant)
- **Bluetooth:** bluetooth.service + bluez

## Network
- **Freezer:** 192.168.0.111/24, enp6s0 (e8:9c:25:df:0d:e7), WoL enabled
- **Snowpi (RPi4, DietPi):** 192.168.1.35 (Tailscale: 100.83.33.67)
- **Tailscale:** tailscaled, 100.x.x.x range
- **DNS:** systemd-resolved → Pi-Hole on Snowpi (192.168.1.35 + 100.83.33.67). MagicDNS: 100.100.100.100
- **Virtual:** virbr0 (libvirt), docker bridge networks

## Dotfiles
Bare git repo at `~/.dotfiles`. Remotes: GitHub (sn0wmann1/snowdots), GitLab (sn0wman/snowdots), Snowpi (git-vault). Managed via `~/scripts/dotsync`.

## Backup & Restore Strategy

### Sync chain
`dotsync` → git push GitLab + GitHub → `dot-mirror.sh` → rsync to Snowpi
`boot-sync` (systemd timer) → runs dotsync → rsyncs session DB to Snowpi

### What's backed up
| Data | GitLab | GitHub | Snowpi | Local |
|------|:---:|:---:|:---:|:---:|
| Dotfiles | ✅ | ✅ | ✅ | ✅ |
| AGENTS.md + MEMORY.md | ✅ | ✅ | ✅ | ✅ |
| Session DB | ❌ | ❌ | ✅ | ✅ |
| Projects | ❌ | ❌ | ✅ | ✅ |
| Root configs | ❌ | ❌ | ✅ | ✅ |
| SSH keys | ❌ | ❌ | ❌ | ✅ |
| Wallpapers | ❌ | ❌ | ❌ | ✅ |
| Package lists | ❌ | ❌ | ✅ | ✅ |

### Full PC restore
1. Install CachyOS + base packages: `pacman -S --needed - < pkglist.txt`
2. `git clone git@gitlab.com:sn0wman/snowdots.git ~/Dotfiles`
3. `~/Dotfiles/scripts/dotsync` → populate `~/.opencode/` + restore configs
4. `~/scripts/restore-dots.sh` → restore SSH, wallpapers, projects
5. `rsync snow@100.83.33.67:/mnt/backups/freezer-mirror/opencode-db-backup/opencode.db ~/.local/share/opencode/`

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