#!/bin/bash

# 1. Get Path (From skwd cache or argument)
WALLPAPER="${1:-$(jq -r '.path' "$HOME/.cache/skwd-wall/wallpaper/current.json" 2>/dev/null)}"

# 2. Run Matugen (Updates the cache file using your working template)
matugen image "$WALLPAPER" -m dark

# 3. Pull the ALREADY FORMATTED strings from the cache file
C1=$(grep "color1 =" ~/.cache/skwd-wall/hyprland-colors.conf | awk -F' = ' '{print $2}')
C4=$(grep "color4 =" ~/.cache/skwd-wall/hyprland-colors.conf | awk -F' = ' '{print $2}')
C_INACTIVE=$(grep "inactive =" ~/.cache/skwd-wall/hyprland-colors.conf | awk -F' = ' '{print $2}')

# 4. Inject into Hyprland (No extra wrapping needed now!)
hyprctl keyword general:col.active_border "$C4 $C1 45deg"
hyprctl keyword general:col.inactive_border "$C_INACTIVE"

# 5. UI Refresh
pkill -USR1 kitty
killall -SIGUSR2 caelestia
#hyprctl notify 1 2000 "rgb(8839ef)" "Empire Restored"
