#!/bin/bash

# 1. Get Path
WALLPAPER="${1:-$(jq -r '.path' "$HOME/.cache/skwd-wall/wallpaper/current.json" 2>/dev/null)}"

# 2. Run Matugen (Now fully automatic)
matugen image "$WALLPAPER" --source-color-index 0

# 3. Pull colors from the cache
C1=$(grep "color1 =" ~/.cache/skwd-wall/hyprland-colors.conf | awk -F' = ' '{print $2}')
C4=$(grep "color4 =" ~/.cache/skwd-wall/hyprland-colors.conf | awk -F' = ' '{print $2}')
C_INACTIVE=$(grep "inactive =" ~/.cache/skwd-wall/hyprland-colors.conf | awk -F' = ' '{print $2}')

# 4. Inject into Hyprland
hyprctl keyword general:col.active_border "$C4 $C1 45deg"
hyprctl keyword general:col.inactive_border "$C_INACTIVE"

# 5. UI Refresh
pkill -USR1 kitty
swaync-client -rs 2>/dev/null
killall -SIGUSR2 caelestia 2>/dev/null
