# AGENTS.md - System Context for "Freezer" (Personal Workstation)

## System
- **OS:** CachyOS x86_64 (Arch-based)
- **Hostname:** Freezer (192.168.0.111)
- **Desktop:** Hyprland + Wayland
- **Shell:** Fish + Starship
- **Editor:** `nano` only (do not use `micro`)
- **AI:** Ollama (NVIDIA CUDA) running locally, accessible via LAN

## Storage
```
/dev/sda (931.5G external SSD)
├── sda1: 650G → /mnt/games (ext4, also used for ollama models)
├── sda2: 100G → /mnt/backups (btrfs)
└── sda3: ~181.5G → /mnt/data (btrfs, extra storage)
```

## Key Scripts (in /home/snow/)
- `setup-ollama.sh` - Install ollama-cuda, store models at `/mnt/games/ollama`
- `resize-sda.sh` - Re-partition /dev/sda (unmounts before modifying)
- `scripts/dot-mirror.sh` - Sync Dotfiles to external backup
- `scripts/snow-audit.sh` - System audit (`audit` alias)
- `scripts/health.sh` - Combined Freezer + Snowpi health (`health` alias)

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
- Systemd: `systemctl status/start/restart <service>`

## Network
- Main PC: 192.168.0.111/24
- Snowpi (RPi4, DietPi): 192.168.1.35 (Tailscale: 100.83.33.67)

## Dotfiles
Git repo at `~/Dotfiles`. Managed via `~/scripts/dotsync` (multi-remote) and `~/scripts/oc-sync.sh` (rsync to Snowpi).

## Memory System
**AT START OF EVERY SESSION:** Read `~/.opencode/MEMORY.md` first.

**AFTER EVERY MESSAGE:** If Snow shares preferences, decisions, or important info:
- Ask: "Should I save this to memory?"
- Or proactively update `~/.opencode/MEMORY.md`

**Quick save:** Use `~/bin/mem` script to append to MEMORY.md

## User: Snow
- Prefers: nano editor, fish shell, Hyprland/Wayland
- Wants: Concise responses, ask before changes, plan before coding
- Accesses AI via: Telegram @Snowcodebot, OpenCode CLI