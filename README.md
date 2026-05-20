# ❄️ SnowDots

Hyprland dotfiles managed across machines. Full config (private) on GitLab, sanitized public version on GitHub.

```
OS: CachyOS x86_64
WM: Hyprland
Shell: fish + starship
Terminal: kitty
Fetch: fastfetch
Colors: material-you (matugen)
```

## Structure

```
Dotfiles/
├── fish/          # fish config, functions, conf.d
├── hypr/          # Hyprland config + keybinds
├── kitty/         # Kitty terminal
├── starship/      # Starship prompt
├── fastfetch/     # Fastfetch configs
├── scripts/       # dotsync, audit, publish-public, etc
├── wallpaper/     # Current wallpaper
├── ssh/           # authorized_keys
├── matugen/       # Material You theme templates
├── README.md      # This file
└── README-SETUP.md # Setup instructions
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `dotsync` | Unified sync - pulls/pushes to GitLab, offers GitHub publish |
| `publish-public.sh` | Strips personal info, pushes sanitized copy to GitHub |
| `snow-audit.sh` | System audit with Git diff |
| `audit-dots.sh` | SnowPi dotfile audit |
| `wall-sync.sh` | Wallpaper + theme sync |
| `fuzzel-control.sh` | Fuzzy launcher with material-you colors |

## Workflow

```bash
dotsync  # sync to GitLab, optionally to GitHub
```

See [README-SETUP.md](README-SETUP.md) for setup details.
