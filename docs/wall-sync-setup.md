# Wall-Sync Setup Documentation

## Current Working Configuration (as of 2026-05-08)

### Files Modified
- `/home/snow/Dotfiles/scripts/wall-sync.sh` - Main sync script
- `/home/snow/Dotfiles/scripts/wall-reset.sh` - Reset script for Super+Shift+W
- `/home/snow/.config/skwd-wall/config.json` - skwd-wall configuration
- `/home/snow/.config/skwd/config.toml` - skwd daemon config

### What Works ✅
1. **skwd wall toggle** (Super+W): Changes wallpaper, applies matugen colors
2. **Super+Shift+W** (wall-reset.sh): Re-applies current wallpaper with colors
3. **Notifications**: Single notification with wallpaper thumbnail + filename
4. **Color syncing**: Hyprland borders, kitty terminal, skwd GUI all update automatically
5. **Daemons**: awww-daemon + skwd-daemon work together

### Configuration Details

**skwd-wall/config.json:**
- matugen enabled for color generation
- postProcessing calls wall-sync.sh
- Integrations: hyprland, kitty, skwd all configured with reload commands
- notifyOnWallpaperChange: false (let wall-sync handle notifications)

**wall-sync.sh:**
- Runs matugen to generate colors
- Applies hyprland borders from cached colors
- Signals kitty with pkill -USR1
- Restarts skwd-daemon to apply GUI colors

**skwd/config.toml:**
- Simple config, no post_processing (handled by skwd-wall)

### Known Issues / Limitations
1. Sometimes colors may need a moment to apply - normal operation
2. If colors get stuck, Super+Shift+W usually fixes it

### How it Works
- skwd-wall runs matugen automatically when wallpaper changes
- Color files generated:
  - `~/.cache/skwd-wall/hyprland-colors.conf` → hyprland borders
  - `~/.cache/skwd-wall/colors-kitty.conf` → kitty terminal
  - `~/.config/skwd/skwd-colors.json` → skwd GUI
- Each integration has its own reload command (hyprctl, pkill, or auto-reload)
- wall-sync.sh then applies hyprland borders and signals kitty

### Key Commands
```bash
# Change wallpaper
skwd wall toggle

# Reset/refresh colors
Super+Shift+W  (or bash ~/Dotfiles/scripts/wall-reset.sh)

# Manual restart
pkill -9 skwd-daemon; rm -f /run/user/1000/skwd/daemon.sock; skwd-daemon &
```

### Debugging
```bash
# Check logs
tail -f ~/.local/share/wall-sync/logs/wall-sync.log

# Check generated colors
cat ~/.cache/skwd-wall/hyprland-colors.conf
cat ~/.cache/skwd-wall/colors-kitty.conf
cat ~/.config/skwd/skwd-colors.json
```