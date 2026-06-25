# SnowDots Architecture

## System Overview

| Component | Detail |
|-----------|--------|
| **OS** | CachyOS (Arch-based), kernel 6.x |
| **DE/WM** | Hyprland + Wayland |
| **Shell** | Fish + Starship prompt |
| **Config dir** | `~/Dotfiles/` (bare git repo at `~/.dotfiles`, managed by `dotsync`) |
| **Hostname** | Freezer (192.168.0.111) |
| **GPU** | NVIDIA (proprietary) |
| **Keyboard** | MAD68 HE (PID 0x1058, 32-byte HID reports) |

---

## 1. Color System

### Flow

```
skwd wall toggle (Super+W)
        │
        ▼
skwd-daemon picks random wallpaper
        │
        ▼
skwd-wall postProcessing: wall-sync.sh
   (or matugen config post_processing runs wall-sync.sh)
        │
        ├─ awww img <wallpaper> --fade 0.3s    ← wallpaper transition
        ├─ matugen image <wallpaper>            ← color generation
        ├─ rgb-sync.sh                          ← OpenRGB + keyboard
        ├─ hyprctl borders update               ← border colors
        ├─ pkill -USR1 kitty                    ← kitty colors
        ├─ swaync-client -rs                    ← notification daemon
        ├─ fuzzel colors                        ← app launcher
        ├─ btop theme                           ← system monitor
        ├─ fastfetch config                     ← fetch colors
        ├─ ACCELA accent                        ← audio visualizer
        ├─ forkgram palette                     ← Telegram colors
        ├─ waylock colors                       ← fallback lock
        ├─ Brave theme                          ← browser
        └─ cursor-colors.sh                     ← cursor theme
```

### matugen config.toml — all templates

Located at `~/.config/matugen/config.toml` (source: `~/Dotfiles/matugen/config.toml`).

| Template | Output | Applies to |
|----------|--------|------------|
| hyprland | `~/.cache/skwd-wall/hyprland-colors.conf` | Hyprland borders |
| kitty | `~/.cache/skwd-wall/colors-kitty.conf` | Kitty terminal |
| fuzzel | `~/.cache/skwd-wall/fuzzel-colors.ini` | Fuzzel launcher |
| skwd | `~/.cache/skwd-wall/colors.json` | skwd GUI, scripts |
| caelestia | `~/.local/state/caelestia/scheme.json` | Caelestia shell (auto-reloads) |
| swaync | `~/.cache/skwd-wall/swaync.css` | Notification daemon |
| steam | `~/.../steamui/skins/.../matugen.css` | Steam (Millennium skin) |
| steam_transparency | `~/.../transparency.css` | Steam transparency |
| steam_experimental | `~/.../experimental-import.css` | Steam header |
| vencord | `~/.config/Vencord/themes/matugen.theme.css` | Discord (Vencord) |
| brave | `~/.config/BraveSoftware/.../current-theme.css` | Brave browser |
| brave-site | `~/.cache/skwd-wall/brave-theme.css` | Brave new tab |
| gtk3 | `~/.config/gtk-3.0/gtk.css` | GTK3 apps |
| gtk4 | `~/.config/gtk-4.0/gtk.css` | GTK4 apps |
| luatools | `~/.cache/skwd-wall/luatools-colors.json` | Luatools (post_hook applies) |
| spicetify | `~/.config/spicetify/Themes/Matugen/color.ini` | Spotify |
| starship | `~/.config/starship.toml` | Shell prompt |
| opencode | `~/.config/opencode/themes/matugen.json` | OpenCode AI |
| sddm_silent | `~/.cache/skwd-wall/sddm-silent.conf` | SDDM (login screen) |
| hyprlock | `~/.config/hypr/hyprlock/matugen/matugen-hyprlock.conf` | Lock screen |
| wlogout | `~/.config/wlogout/style.css` | Power menu |
| rofi | `~/.config/rofi/launchers/styles/shared/colors.rasi` | Rofi launcher |
| forkgram | `~/.cache/skwd-wall/forkgram.tdesktop-palette` | Telegram |

### matugen source color index = 0 (most prominent color)

---

## 2. Wallpaper System

### Components

| Component | Role |
|-----------|------|
| **skwd-daemon** | Wallpaper picker, browser, downloader. Runs as systemd user service (`systemctl --user start skwd`) |
| **skwd-wall** | GUI frontend for skwd. Config at `~/.config/skwd-wall/config.json` |
| **awww-daemon** | Wallpaper setter (Wayland). Sets image with fade transitions |
| **matugen** | Color extraction from wallpaper image. Runs on each wallpaper change |

### Trigger chain

```
Super+W → skwd wall toggle
                │
                ▼
skwd-daemon changes wallpaper via awww
                │
                ▼
skwd-wall postProcessing: wall-sync.sh (debounced 5s)
                │
                ├─ awww img <wall> --fade 0.3s         (already set by skwd, just ensures)
                ├─ matugen image <wall>                 (generates all color files)
                ├─ rgb-sync.sh                          (OpenRGB + keyboard)
                ├─ hyprctl reload + border update
                ├─ app/UI color reloads...
                └─ notify-send "Wallpaper Changed"
```

### skwd-wall config.json key settings

- `pickOnlyMode: true` — picker closes after selection
- `paper.engine: "skwd-paper"` — but awww is used directly for transition
- `animations: false` — no animations
- `ExternalMatugenCommand: "matugen image %path% --source-color-index 0"` — redundant with post_processing in matugen config
- `postProcessing: [wall-sync.sh, rename-wallpapers.sh]`
- `postProcessOnRestore: true`

### Hybrid: skwd-wall integrations + matugen post_processing

Both can trigger color generation. Currently:
- skwd-wall runs `ExternalMatugenCommand` before `postProcessing`
- matugen config has `[post_processing] command = wall-sync.sh`
- wall-sync.sh debounces 5s to avoid double-runs

### Wallpaper directory

`~/Pictures/Wallpapers/` — 398 sequential webp files (001.webp–398.webp). Renamed by `rename-wallpapers.sh`.

---

## 3. RGB/Lighting

### OpenRGB (internal components)

- **Fans** (device 2): wallpaper accent hue, L=0.20, S=0.80, brightness 50
- **RAM** (devices 0,1): -20° hue shift (compensates ENE yellow tint), L=0.30, S=0.90
- Single `openrgb --mode static --color HEX --brightness 50` call

### MAD68 HE Keyboard

**Protocol**: 32-byte HID output report via hidapi. Report descriptor:
- `\x55\x0B` prefix for frame data (per-key animation)
- `\x07\x41` prefix for solid color mode

**Custom mode init** (required):
```
0x96 warmup dim (RGB 60,60,60) → wait 50ms → 0x97 enable custom mode → wait 100ms
```

**Solid color** (used by rgb-sync.sh via `mad68-rgb.py`):
```python
data = [7, 65, 2, 0, 0x96, R, G, B, 0xB1, zeros...]  # 32 bytes
```

**Animation** (used by MAD68 HE dashboard at `localhost:3333`):
- `rgb_engine.py` runs as subprocess, receives JSON commands via stdin
- Sends per-key frame data in `\x55\x0B` chunks (26 bytes per chunk, 384 bytes total)
- Map: `matrix_map.json` maps key names → LED indices
- FPS variable (default 10), speed, brightness, animation code

**HID path**: `VID 0x373B, PID 0x1058, interface 1`. Needs udev rule at `/etc/udev/rules.d/99-mad68.rules` for user access.

### rgb-sync.sh (runs on every wallpaper change)

1. Read accent color from `~/.cache/skwd-wall/colors.json`
2. Parse to HSV, output two colors:
   - OpenRGB: same H, L=0.20, S=0.80
   - Keyboard: same H, L=0.45, S=0.85 (brighter for LED readability)
3. `openrgb --mode static --color HEX`
4. `python3 mad68-rgb.py HEX`

---

## 4. Caelestia (Quickshell Shell)

### Architecture

Caelestia is a Quickshell-based desktop shell handling: lock screen, notifications, sidebar, power menu, wallpaper picker, color connectivity.

**Live config**: `~/.config/quickshell/caelestia/` (separate copy from `~/Dotfiles/quickshell/caelestia/` — NOT symlinked)

**Start**: `qs -c caelestia -d` in hyprland.conf `exec-once`

**Restart**: `Super+Shift+R` → `~/Dotfiles/scripts/caelestia-restart.sh` (pkill → clean IPC sockets → daemonize → hyprctl reload)

### Lock Screen

**Components**:
- `Lock.qml` — WlSessionLock + IPC handler (target `lock`)
- `LockSurface.qml` — Screencopy + password input (PAM)
- `Center.qml` — Clock, password field, wallpaper background
- `Content.qml` — Side panels (weather, fetch, media, resources, notifs)

**IPC calls** (space-separated, NOT dotted):
```
caelestia shell lock lock       # Lock the screen  ✓
caelestia shell lock unlock     # Unlock            ✓
caelestia shell lock isLocked   # Check status      ✓
```

**QUIRK**: `qs ipc call` expects target and function as **separate CLI args**. `caelestia shell lock.lock` is ONE arg → treated as target name only → "Function required to send message."

**Triggers**:
- `Super+L` → `caelestia shell lock lock`
- hypridle: `lock_cmd` + `before_sleep_cmd`
- Boot: `exec-once = hyprlock` (not caelestia)

### Notifications

NotificationServer via `Notifs.qml`. Swipe-to-dismiss on lock screen. Replaces swaync.

### Sidebar (Drawers)

- `Super+N` → `caelestia shell drawers toggle sidebar`
- Hover zone: 100px from top, 150px from right edge

### Auto-reload

Caelestia watches `~/.local/state/caelestia/scheme.json` via inotify. When matugen writes new scheme, caelestia reloads colors during 300ms fade. No kill/restart needed.

---

## 5. Keybindings Reference

### System
| Key | Action |
|-----|--------|
| Super+W | Wallpaper toggle |
| Super+Shift+W | Wall-reset (re-apply colors) |
| Super+L | Lock (caelestia) |
| Super+Return | Fuzzel control center |
| Super+Space | App launcher |
| Super+Escape | Power menu (wlogout) |
| Super+Shift+M | Exit Hyprland |
| Super+Shift+R | Restart caelestia |

### Apps
| Key | Action |
|-----|--------|
| Super+B | Brave |
| Super+D | Discord |
| Super+F | Thunar file manager |
| Super+Q | Kitty terminal |
| Super+S | Steam launcher |
| Super+T | Trayscale (Tailscale GUI) |
| Super+V | Clipse clipboard |
| Super+X | Toggle fullscreen |
| Super+Z | Toggle float |

### Media
| Key | Action |
|-----|--------|
| Fn+Up / Super+Up | Volume up |
| Fn+Down / Super+Down | Volume down |
| Fn+Prev/Play/Next | Media controls |
| Super+Shift+V | Toggle unlimited volume |

### Hardware
| Key | Action |
|-----|--------|
| Super+PageUp/Down | Monitor brightness (DDC) |

### Screenshots
| Key | Action |
|-----|--------|
| Super+Shift+S | Region screenshot |
| Super+Alt+S | Window screenshot |
| Super+Insert | Full screenshot |
| Super+Shift+T | Text extract (OCR) |

---

## 6. Scripts Reference

| Script | Location | Purpose |
|--------|----------|---------|
| wall-sync.sh | `~/Dotfiles/scripts/wall-sync.sh` | Main color sync after wallpaper change |
| wall-reset.sh | `~/Dotfiles/scripts/wall-reset.sh` | Re-apply colors from current wallpaper |
| rgb-sync.sh | `~/Dotfiles/scripts/rgb-sync.sh` | OpenRGB + keyboard color |
| mad68-rgb.py | `~/.local/bin/mad68-rgb.py` | MAD68 keyboard solid color |
| caelestia-restart.sh | `~/Dotfiles/scripts/caelestia-restart.sh` | Kill + restart caelestia |
| rename-wallpapers.sh | `~/Dotfiles/scripts/rename-wallpapers.sh` | Safe sequential rename (3-stage) |
| volume-log.sh | `~/.local/bin/volume-log.sh` | Volume change with notification |
| brightness-log.sh | `~/.local/bin/brightness-log.sh` | Brightness change with notification |
| volume-unlimited-toggle.sh | `~/.local/bin/volume-unlimited-toggle.sh` | Toggle volume cap |
| shot-smart.sh | `~/Dotfiles/scripts/shot-smart.sh` | Screenshot (region/window/full) |
| textextract | `~/.local/bin/textextract` | OCR screenshot → clipboard |
| fuzzel-control.sh | `~/Dotfiles/scripts/fuzzel-control.sh` | Fuzzel launcher for control panel/snippets |
| app-launcher.sh | `~/Dotfiles/scripts/app-launcher.sh` | Application launcher |
| steam-launch.sh | `~/Dotfiles/scripts/steam-launch.sh` | Steam game launcher |
| night-light.sh | `~/Dotfiles/scripts/night-light.sh` | Toggle hyprsunset |
| safe-kill.sh | `~/Dotfiles/scripts/safe-kill.sh` | Kill focused window safely |
| hypr-float.sh | `~/Dotfiles/scripts/hypr-float.sh` | Toggle window float |
| wlogout.sh | `~/scripts/wlogout.sh` | Power menu |
| cursor-colors.sh | `~/Dotfiles/scripts/cursor-colors.sh` | Update cursor theme colors |
| brave-theme.sh | `~/Dotfiles/scripts/brave-theme.sh` | Update Brave theme |
| forkgram-apply-palette.sh | `~/Dotfiles/scripts/forkgram-apply-palette.sh` | Apply Telegram palette |
| snow-audit.sh | `~/Dotfiles/scripts/snow-audit.sh` | System audit |
| health.sh | `~/Dotfiles/scripts/health.sh` | Freezer + Snowpi health |
| dotsync | `~/Dotfiles/scripts/dotsync` | Dotfiles bare repo sync |
| dotpull | `~/Dotfiles/scripts/dotpull` | Pull Dotfiles updates |
| dot-mirror.sh | `~/Dotfiles/scripts/dot-mirror.sh` | Mirror Dotfiles to external backup |
| publish-public.sh | `~/Dotfiles/scripts/publish-public.sh` | Sanitize + push to GitHub |
| oc-sync.sh | `~/Dotfiles/scripts/oc-sync.sh` | OC config sync to Snowpi |

---

## 7. Dotfiles Management

### Bare Git Repo

Dotfiles tracked via bare git repo at `~/.dotfiles`:
```bash
alias dotsync='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

**Config** (`~/.config/git/config` or global): aliases add/commit/push for dotfiles.

### Sync Strategy

| Remote | URL | Content |
|--------|-----|---------|
| GitLab origin | `gitlab.com/sn0wman/snowdots` | Full dotfiles (private) |
| GitHub | `github.com/sn0wmann1/snowdots` | Sanitized (public) |

**GitHub publish**: `publish-public.sh` clones sanitized copy (removes `.opencode/`, `.ssh/`, replaces real IPs). Full clone (no `--depth 1` — shallow clone caused push failures).

### Config Sync

- `dotsync` → `~/Dotfiles/scripts/dotsync` (aliases with add/commit/push)
- `dotpull` → `~/Dotfiles/scripts/dotpull` (pull remote)
- `boot-sync.sh` → boot: sync + memory update

---

## 8. Hyprland Config

### hyprland.conf (key sections)

| Section | Details |
|---------|---------|
| Colors | `source = ~/.cache/skwd-wall/hyprland-colors.conf`, fallback hex values |
| Monitor | `2560x1440@180`, scale 1 |
| NVIDIA | env vars: `LIBVA_DRIVER_NAME=nvidia`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, etc. |
| Input | kb_layout `us, iq(ku_ara), ara`, alt_shift toggle |
| Decorations | rounding 10, blur (size 3, passes 2), no shadow |
| Animations | snappy bezier `0.2, 0.1, 0.2, 1` |
| Misc | `allow_session_lock_restore = true`, `enable_swallow = true` |

### hyprlock.conf

Layout (top→bottom):
1. Status bar (top-left)
2. Greeting (y=330)
3. Clock (y=250)
4. Date (y=190)
5. Album art (bottom-right, 100px, square)
6. Now playing (bottom-right)
7. Input field (center, fully transparent when empty)
8. Caps lock indicator (y=-45)
9. User label (y=50, valign=bottom)

Weather: Erbil, Celsius via wttr.in, cached 1hr in `/tmp/weather-cache`.

### hypridle.conf

| Listener | Action |
|----------|--------|
| lock_cmd | `caelestia shell lock lock` |
| before_sleep_cmd | `caelestia shell lock lock` |
| after_sleep_cmd | `hyprctl dispatch dpms on` |
| Evening 19:00 | `hyprsunset --temperature 4500` |
| Night 22:00 | `hyprsunset --temperature 3000` |
| Morning 07:00 | `pkill hyprsunset` |

---

## 9. OpenCode AI Integration

### Subagents (10)

| Agent | Purpose |
|-------|---------|
| health-monitor | Disk temps, services, audit |
| pkg-manager | Arch packages, AUR, cache |
| snowpi-bridge | SSH to RPi4 |
| tailscale-manager | Tailscale status/IP |
| docker-orchestrator | Docker compose up/down |
| docker-cleanup | Prune images, volumes |
| backup-agent | Btrfs snapshots, verify |
| disk-usage | Analyze /dev/sda space |
| dotfiles-sync | Git add/commit/push |
| log-scanner | journalctl + Hyprland logs |

### Config
- Active: `~/.config/opencode/opencode.json` (NOT the symlink at `~/.opencode/`)
- Theme: `~/.config/opencode/themes/matugen.json` (generated by matugen)
- Permissions: `"*": "allow"` + dangerous `ask`

---

## 10. MAD68 HE Dashboard

### Components

- **Server**: Node.js Express + WebSocket at `localhost:3333`
- **Engine**: `rgb_engine.py` (Python, hidapi) — receives JSON via stdin, sends frame data
- **Web UI**: Browser-based animation preview + control

### Startup
```bash
cd ~/MAD-68-custom-animation && node server.js &
```

### Data flow

```
Browser UI → WebSocket → server.js → stdin → rgb_engine.py → HID → Keyboard
```

---

## 11. Troubleshooting

### Lock doesn't work (Super+L / hypridle)

**Symptoms**: "Function required to send message" or screen doesn't lock.

**Checks**:
1. Is caelestia running? `pgrep -f "qs -c caelestia"`
2. Correct command? Must be `caelestia shell lock lock` (space-separated, NOT `lock.lock`)
3. Check `loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p LockedHint`
4. Restart caelestia: `Super+Shift+R`
5. Check caelestia logs: `journalctl --user -u quickshell-caelestia`

**Common causes**:
- hyprlock still holds session lock (shouldn't — hyprlock exits on unlock)
- caelestia crashed (restart with `caelestia-restart.sh`)

### Wallpaper colors not updating

**Checks**:
1. Wallpaper set? Check `awww query`
2. matugen succeeded? `cat ~/.local/share/wall-sync/logs/wall-sync.log`
3. `hyprctl reload` needed? Run manually
4. Run manually: `bash ~/Dotfiles/scripts/wall-reset.sh`

### Keyboard RGB not changing

**Checks**:
1. Keyboard connected? Check `lsusb | grep 373B`
2. udev rule exists? `/etc/udev/rules.d/99-mad68.rules`
3. Custom mode enabled? `python3 ~/.local/bin/mad68-rgb.py HEXCOLOR`
4. Dashboard engine running? `pgrep -f rgb_engine.py`
5. Check `~/.local/share/wall-sync/logs/wall-sync.log` for rgb-sync errors

### OpenRGB not working

**Checks**:
1. `openrgb --server` running? `pgrep -x openrgb`
2. Devices listed? `openrgb --devices`
3. Connection refused? Start server: `openrgb --server &`

### Caelestia not starting

**Checks**:
1. `pgrep -f "qs -c caelestia"` — running?
2. Try start: `qs -c caelestia -d`
3. Has `-d` (daemonize) not `-n` (no-duplicate) in exec-once
4. Check quickshell binary exists: `which quickshell`

### hyprlock fails at boot

**Check**: `/usr/local/bin/hyprlock` vs `/usr/bin/hyprlock`. If local bin exists but has missing libs, remove it: `sudo rm /usr/local/bin/hyprlock` (run in own terminal, no sudo via OC).

### Colors race condition

If colors flicker between old and new scheme: wall-sync.sh has 5s debounce. If skwd-wall runs both ExternalMatugenCommand AND postProcessing, matugen runs twice. Fix: remove ExternalMatugenCommand from skwd-wall config (matugen's own post_processing handles colors).

### Steam Millennium theme not applying

Run `chmod a+wr /opt/spotify/Apps -R && spicetify backup apply` (sudo needed). For Steam: Millennium manages CSS, check `~/.steam/steam/ubuntu12_32/` symlinks exist.

---

## 12. System Services

| Service | Status | Purpose |
|---------|--------|---------|
| `skwd-daemon` | user service | Wallpaper daemon |
| `awww-daemon` | user (~/.xprofile) | Wallpaper setter |
| `openrgb --server` | user (exec-once) | RGB controller server |
| `caelestia` | user (qs -d) | Desktop shell |
| `hypridle` | user (exec-once) | Idle management |
| `clipse` | user (exec-once) | Clipboard manager |
| `polkit-gnome` | user (exec-once) | Authentication agent |
| `trayscale` | user (exec-once, delayed) | Tailscale GUI |
| `coolercontrol` | user (exec-once, delayed) | Fan control |
| `oc-fast-sync.timer` | systemd user timer | OC memory sync (30min) |
| `opencode-serve.service` | systemd | OC remote (port 4096, unused — snowpi only) |
| `services-dashboard.py` | user (exec-once) | Dynamic service dashboard (port 80) |

> Services dashboard at **`http://localhost/`** — auto-detects running/idle services via `ss`.
> Full list with ports in #localhost-services 

---

## 13. Storage Layout

```
/dev/sda (931.5G external SSD)
├── sda1: 650G → /mnt/games (ext4)     # also ollama models
├── sda2: 100G → /mnt/backups (btrfs)   # dotfiles mirror + snapshots
└── sda3: ~181.5G → /mnt/data (btrfs)   # extra storage
```

---

## 14. Network

| Device | IP | Tailscale |
|--------|-----|-----------|
| Freezer | 192.168.0.111 | 100.83.33.67 |
| Snowpi | 192.168.1.35 | 100.120.197.52 |

---

## 15. Known Issues

1. **Lock caelestia silently fails**: `caelestia shell lock lock` returns exit 0 but screen doesn't lock. Root cause unknown — possible WlSessionLock protocol issue with Hyprland. hyprlock at boot works fine.
2. **hyprlock binary conflict**: `/usr/local/bin/hyprlock` has missing lib (`libhyprutils.so.11`). Workaround: use `/usr/bin/hyprlock` (pacman version). Remove local binary with `sudo rm`.
3. **Snowpi kitty terminfo**: SSH shows `terminfo not found`. Fix: `sudo ln -s /usr/share/terminfo/k/kitty /usr/share/terminfo/x/xterm-kitty` on Snowpi.
4. **NVIDIA VRAM OOM**: Heavy WebGL content (e.g., rauno.me) can exhaust 12GB VRAM. Hard crash, needs reboot.
5. **spicetify permissions**: Needs `sudo chmod a+wr /opt/spotify/Apps -R` after Spotify updates.
6. **yay --locked flag**: Metropolis PKGBUILD has `--locked` in cargo build. Edit PKGBUILD to remove after every yay upgrade.
