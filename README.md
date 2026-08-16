# ❄️ SnowDots

Hyprland dotfiles for Arch Linux. Snow-themed, material-you colored, multi-machine.

```
OS: CachyOS / Arch x86_64
WM: Hyprland (Lua config)
Shell: caelestia — quickshell/QML desktop shell (bar, nexus, lock, rgb)
Terminal: kitty
Prompt: fish + starship
Fetch: fastfetch
Launcher: fuzzel + app-launcher
Colors: matugen (Material You, wallpaper-driven)
Wallpaper: skwd + wall-sync
RGB: OpenRGB + MAD68 + Govee (wallpaper-synced)
```

## Fonts

| Where | Font |
| ------- | ------ |
| Shell UI (caelestia body/label/title) | **Inter** |
| Shell mono / clock | **JetBrainsMono Nerd Font** |
| Terminal (kitty) | **JetBrainsMono Nerd Font** 13 |
| Power menu (wlogout) | **JetBrainsMono Nerd Font Propo** 16 |

```bash
sudo pacman -S --needed ttf-inter ttf-jetbrains-mono-nerd
```

## Quick Start

```bash
curl -sL https://raw.githubusercontent.com/sn0wmann1/snowdots/main/scripts/install.sh | bash
```

This clones the repo to `~/Dotfiles` and launches the interactive installer.
No git? The script installs it. No dependencies? You pick what to install.

Or clone and run manually:

```bash
git clone https://github.com/sn0wmann1/snowdots.git ~/Dotfiles
bash ~/Dotfiles/scripts/snow-dots install
```

### GitLab mirror

```bash
curl -sL https://gitlab.com/sn0wman/snowdots/-/raw/main/scripts/install.sh | bash
```

## Features

- **caelestia** — quickshell/QML shell: top bar (workspaces, clock, tray, popouts), Nexus dashboard (apps / network / services), lock screen, RGB control panel, background visualiser
- **Hyprland** — Lua config (`hypr/hyprland.lua`), smooth animations, material-you colors
- **matugen** — Material You theme regenerated from wallpaper (kitty, hypr, GTK, QML, shell)
- **RGB sync** — wallpaper accent → case LEDs (OpenRGB), keyboard (MAD68), Govee strip; bridge preserves per-device brightness, boot sync waits for full device enumeration
- **kitty** — GPU terminal, 92% opacity, material-you theme
- **fish + starship** — autocomplete, fzf, minimal prompt
- **fuzzel** — fuzzy launcher + app launcher menu
- **wlogout** — power menu with wallpaper-accented icons
- **wall-sync** — skwd wallpaper daemon + theme regen on change
- **dotsync** — unified git sync across machines (GitLab + sanitized GitHub + Snowpi)
- **swaync** — notification center

## Structure

```
~/
├── Dotfiles/            ← This repo
│   ├── scripts/         ← dotsync, snow-dots, rgb-sync, wall-sync, etc.
│   ├── quickshell/      ← caelestia shell (QML + shell.json config)
│   ├── wlogout/         ← power menu (style.css + recolored icons)
│   ├── fish/            ← config.fish, functions, conf.d/
│   ├── hypr/            ← hyprland.lua, hypridle.conf
│   ├── kitty/           ← kitty.conf
│   ├── matugen/         ← material-you templates
│   ├── starship/        ← starship.toml
│   ├── fastfetch/       ← config.jsonc, logo
│   └── README.md        ← This file
```

## Setup

### Interactive Installer (Recommended)

```bash
bash <(curl -sL https://raw.githubusercontent.com/sn0wmann1/snowdots/main/scripts/snow-dots.sh)
```

**What it does:**

- Backs up current config to `~/.dotfiles-backup-*` before touching anything
- Installs packages (Hyprland, fish, kitty, quickshell, fonts, etc.)
- Sets up symlinks for all configs
- Installs fisher + plugins (if fish is installed)
- Sets fish as default shell (optional)

**Want to undo?** Run `snow-dots restore` and pick your backup.

### Manual setup

```bash
# Symlink configs
ln -sf ~/Dotfiles/fish ~/.config/fish
ln -sf ~/Dotfiles/kitty ~/.config/kitty
ln -sf ~/Dotfiles/quickshell ~/.config/quickshell
ln -sf ~/Dotfiles/wlogout ~/.config/wlogout
ln -sf ~/Dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/Dotfiles/hypr/hyprland.lua ~/.config/hypr/hyprland.lua

# Link scripts
mkdir -p ~/.local/bin
for script in ~/Dotfiles/scripts/*.sh; do
    ln -sf "$script" ~/.local/bin/$(basename "$script")
done
ln -sf ~/Dotfiles/scripts/dotsync ~/.local/bin/dotsync
```

### Package dependencies (Arch)

```bash
sudo pacman -S --needed hyprland fish kitty starship fastfetch fuzzel \
  swaync wlogout quickshell hyprlock matugen grim slurp swappy \
  wl-clipboard polkit-kde-agent xdg-desktop-portal-hyprland \
  ttf-inter ttf-jetbrains-mono-nerd noto-fonts-emoji \
  openrgb python-openrgb python-hid python-requests
```

## Sync

```bash
dotsync
```

On Freezer: pulls from GitLab, pushes to GitLab + optionally GitHub (sanitized) + Snowpi.
On SnowPi: pulls from GitLab, pushes to GitLab.

`boot-sync` (user timer, once at boot): dotsync, dot-mirror to `/mnt/backups`, session DB rsync to Snowpi.

### GitHub publish

`dotsync` asks to publish a sanitized copy (`scripts/publish-public.sh`):

1. Clones to a temp dir, strips personal info (SSH keys, IPs, `.opencode/`)
2. Force-pushes the public-safe copy to GitHub

## Remotes

```
gitlab → git@gitlab.com:sn0wman/snowdots.git
github → git@github.com:sn0wmann1/snowdots.git (sanitized)
snowpi → snow@100.83.33.67:/home/snow/git-vault/Dotfiles.git
```

## Keybinds

| Key | Action |
| ----- | -------- |
| Super + Q | kitty |
| Super + Return | fuzzel launcher |
| Super + Space | app launcher |
| Super + Escape | wlogout |
| Super + L | lock (caelestia) |
| Super + D | discord |
| Super + F | thunar |
| Super + R | RGB panel (quickshell) |
| Super + B | brave |
| Super + T | trayscale |
| Super + V | clipse (clipboard) |
| Super + C | close window |
| Super + Shift + C | force-kill |
| Super + Shift + R | restart caelestia |
| Super + Shift + M | logout (hyprctl exit) |
| Super + W | toggle wallpaper |
| Super + Shift + W | reset wallpaper + theme |
| Super + N | Nexus sidebar |
| Super + Shift + B | brave incognito |

## Wallpaper & Themes

Place wallpapers in `~/Pictures/Wallpapers/` and switch with `Super + W` or:

```bash
bash ~/Dotfiles/scripts/wall-sync.sh
```

This runs matugen on the current wallpaper and updates kitty, hypr, GTK, caelestia tokens, and RGB LEDs.

## RGB sync

`rgb-sync.sh` reads the wallpaper accent → converts to a unified LED color → applies via:

- `rgb-bridge` (REST API, preserves per-device brightness) → OpenRGB + MAD68 + Govee
- Direct fallback: `fade-rgb.py` (smooth fade) + `govee-led.py`

At boot it waits for OpenRGB to enumerate **all** devices (motherboard controller registers ~7s after server start) and for the wallpaper accent before animating.

## License

MIT
