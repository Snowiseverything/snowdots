# ❄️ SnowDots

Hyprland dotfiles for Arch Linux. Snow-themed, material-you colored, multi-machine.

```
OS: CachyOS / Arch x86_64
WM: Hyprland
Shell: fish + starship
Terminal: kitty
Fetch: fastfetch
Launcher: fuzzel / rofi
Colors: matugen (Material You)
Bar: waybar
Notifications: swaync
```

## Quick Start

```bash
bash <(curl -sL https://raw.githubusercontent.com/Snowiseverything/snowdots/main/scripts/snow-dots.sh)
```

Or clone and run:

```bash
git clone https://github.com/Snowiseverything/snowdots.git ~/Dotfiles
bash ~/Dotfiles/scripts/snow-dots.sh
```

## Features

- **Hyprland** — Dynamic tiling, smooth animations, material-you colors
- **fish** — Auto-complete, autopair, pure prompt, fuzzy file nav with matchmaker
- **kitty** — GPU-accelerated terminal with material-you theme
- **starship** — Minimal, fast prompt
- **waybar** — Status bar with workspaces, volume, brightness, network, clock
- **fuzzel** — Fuzzy app launcher with material-you colors
- **swaync** — Notification center
- **dunst** — Lightweight notifications
- **matugen** — Material You theme generator from wallpaper
- **wall-sync** — Automatically generate theme from wallpaper
- **dotsync** — Unified git sync across machines

## Structure

```
~/
├── Dotfiles/          ← This repo
│   ├── scripts/       ← dotsync, snow-dots, audit, publish, etc.
│   ├── fish/          ← config.fish, functions, conf.d/
│   ├── hypr/          ← hyprland.conf, hypridle.conf, keybinds
│   ├── kitty/         ← kitty.conf + material-you theme
│   ├── starship/      ← starship.toml
│   ├── fastfetch/     ← config.jsonc, logo
│   ├── waybar/        ← style.css, config
│   ├── swaync/        ← notification config
│   ├── dunst/         ← dunstrc
│   ├── wofi/          ← wofi style
│   ├── wallpaper/     ← current wallpaper + themes
│   ├── matugen/       ← material-you templates
│   ├── ssh/           ← authorized_keys placeholder
│   ├── README.md      ← This file
│   └── README-SETUP.md ← Legacy (content merged here)
```

## Setup

### 1. Interactive Installer

The easiest way is `snow-dots.sh` — an interactive snow-themed installer:

```
bash ~/Dotfiles/scripts/snow-dots.sh
```

It will:
- Detect your distro (Arch, Debian, Fedora)
- Install packages (Hyprland, fish, kitty, waybar, fonts, etc.)
- Set up symlinks for all configs
- Install fisher + plugins
- Set fish as default shell
- Install matchmaker fuzzy finder

Run it once. Re-run anytime for updates.

### 2. Manual Setup

```bash
# Symlink configs
ln -sf ~/Dotfiles/fish ~/.config/fish
ln -sf ~/Dotfiles/kitty ~/.config/kitty
ln -sf ~/Dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/Dotfiles/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
ln -sf ~/Dotfiles/hypr/hypridle.conf ~/.config/hypr/hypridle.conf
ln -sf ~/Dotfiles/starship/starship.toml ~/.config/starship.toml

# Link scripts
mkdir -p ~/.local/bin
for script in ~/Dotfiles/scripts/*.sh; do
    ln -sf "$script" ~/.local/bin/$(basename "$script")
done
ln -sf ~/Dotfiles/scripts/dotsync ~/.local/bin/dotsync
```

### 3. Package Dependencies

**Arch:**
```bash
sudo pacman -S --needed hyprland fish kitty waybar wofi fuzzel swaync \
  dunst wlogout starship fastfetch grim slurp swappy wl-clipboard \
  polkit-kde-agent xdg-desktop-portal-hyprland \
  ttf-jetbrains-mono-nerd ttf-meslo-nerd noto-fonts-emoji

# AUR
yay -S matugen-bin hyprland-guiutils
```

**Debian/Ubuntu:**
```bash
sudo apt install fish kitty starship fastfetch grim slurp wl-clipboard \
  fonts-jetbrains-mono fonts-noto-color-emoji
# Hyprland must be built from source or use the hyprland repo
```

## Sync

```bash
dotsync
```

On Freezer: pulls from GitLab, pushes to GitLab + optionally to GitHub (sanitized).
On SnowPi: pulls from GitLab, pushes to GitLab + optionally to peer.

### GitHub Publish

After `dotsync`, you'll be asked:

```
📢 Publish sanitized version to GitHub? [y/N]
```

This runs `scripts/publish-public.sh` which:
1. Clones the repo to a temp directory
2. Strips personal info (SSH keys, IPs, `.opencode/`)
3. Asks confirmation
4. Force-pushes sanitized copy to GitHub

This keeps private info on GitLab and only polished, public-safe content on GitHub.

## Remotes

**Freezer (desktop)**
```
gitlab → git@gitlab.com:sn0wman/snowdots.git
github → git@github.com:Snowiseverything/snowdots.git
```

**SnowPi (RPi4)**
```
origin → git@gitlab.com:sn0man/snowpi-dotfiles.git
```

## Keybinds

| Key | Action |
|-----|--------|
| Super + Return | kitty |
| Super + D | fuzzel launcher |
| Super + Q | Close window |
| Super + F | Toggle fullscreen |
| Super + V | Toggle floating |
| Super + 1-9 | Switch workspace |
| Super + Shift + 1-9 | Move window to workspace |
| Super + Shift + C | Kill window |
| Super + Shift + S | Screenshot region |
| Super + L | Lock screen |
| Super + Space | Toggle layout |
| Super + arrows | Move focus |
| Super + Print | Screenshot full |
| Ctrl + F | matchmaker (files) |
| Ctrl + R | matchmaker (files + dirs) |
| Alt + C | matchmaker (dirs) |

## Wallpaper & Themes

Place wallpapers in `~/Dotfiles/wallpaper/` and run:

```bash
bash ~/Dotfiles/scripts/wall-sync.sh
```

This runs matugen on the current wallpaper and updates kitty, waybar, fuzzel, and hyprland colors.

## License

MIT
