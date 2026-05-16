# User Memory

## About Snow
- Uses Arch-based Linux (CachyOS on Freezer, DietPi on Snowpi)
- Prefers: nano editor, fish shell, Hyprland/Wayland
- Accesses AI from phone via Telegram (@Snowcodebot)

## Preferences
- Concise responses
- Ask confirmation before making changes
- Use code blocks for terminal commands
- Always plan before coding

## Systems
- Freezer: Main workstation (192.168.0.111)
- Snowpi: RPi4 backup (Tailscale: 100.120.197.52)

## Session Notes (2026-05-12)

### Today's Setup
- Unified .hermes → .opencode for both OpenCode and Hermes
- Hermes gateway running as systemd service on Snowpi
- Telegram @Snowcodebot connected and working
- Memory system: AGENTS.md + MEMORY.md shared across both machines
- Quick save command: ~/bin/mem "thing to remember"
- After every session: ask "Should I save anything to memory?"

### Quickshell Sidebar (Notifications)
- Super+N toggles notification sidebar (was swaync)
- Super+Shift+B opens Brave incognito (was blur toggle - broken)
- Sidebar opens on hover in top-right corner (100px from top, 150px from right)
- Sidebar does NOT auto-hide when hovering notifications - acceptable tradeoff
- Current version: stable, no further changes needed

### Key Keybinds
- Super+N: Toggle quickshell notification sidebar
- Super+Shift+B: Brave incognito

### Session (2026-05-14)
- Fixed btop neon green colors - made bracket letters purple (#e4b7f3)
- Created "working" git tag on GitLab for rollback
- Added local backup sync status to snow-audit.sh
- System check: All scripts work (dotsync, wall-sync, audit)
- Found failed service: xdg-desktop-portal-hyprland (fixed with daemon-reload)
- Reinstalled Vencord for Discord
- Steam: Added windowrule to float notifications, removed workspace rule
- GPU crash: NVIDIA OOM from rauno.me in Brave - 12GB VRAM exhausted
- Fixed btop theme to use wallpaper primary color dynamically (was hardcoded #999999)
- Pushed wall-sync.sh fix to GitLab
- Zed: Fixed opencode path in settings.json (used full path)
- Wallpaper: Fixed stuck on 298.webp - removed skwd-paper, use awww directly
- Killed swaync (old notification daemon)

## 2026-05-14
- Run 'opencode-rename' at end of each session to auto-name new chats

## Session (2026-05-16)
- Switched OC from pnpm to AUR (removed pnpm shim at ~/.local/share/pnpm/opencode)
- Deleted ~/.config/Cursor and ~/.config/cursor (~17MB Cursor editor leftover configs)
- Added fzf fish keybinds: Ctrl+R = vertical history search, Ctrl+T = files, Alt+C = cd with preview
- Alt+C: customized to show `..` for going up, plus eza preview of dir contents
- 63 yay updates pending (needs `yay -Syu` manually — no sudo in CLI)
- Keybind reload rescue: hyprland submap got stuck, fixed with `hyprctl dispatch submap reset`
- Notifications (caelestia) use Colours.palette.m3* — already material you. scheme.json has two writers (caelestia python vs skwd-wall/matugen) that can conflict

## Session (2026-05-16) — OC Config Unification
- OC shared configs moved to `~/Dotfiles/.opencode/` (source of truth)
- `~/.opencode/{AGENTS.md,MEMORY.md,SOUL.md,opencode.json,skills/}` → symlinks to Dotfiles
- Created `scripts/setup-oc-sync.sh` — symlinks shared OC into `~/.opencode/` on any machine
- Added auto-heal OC symlink block to dotsync script
- Snowpi todo: pull Dotfiles, run `setup-oc-sync.sh` to populate skills/ + update MEMORY.md
- Snowpi Tailscale IP: 100.83.33.67 (note: AGENTS.md still shows old IP 100.120.197.52)
