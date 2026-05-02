########################################################################
##  SnowDots — SnowWallsync                             Version: v1.0.0    ##
##  Last Edited: 2026-04-30                                           ##
########################################################################

#!/bin/bash

# 1. Get Path
CACHE_PATH="$HOME/.cache/skwd-wall/wallpaper/current.json"
IF_ARG="$1"

if [ -n "$IF_ARG" ]; then
    WALLPAPER="$IF_ARG"
else
    WALLPAPER=$(jq -r '.path // empty' "$CACHE_PATH")
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    notify-send "wall-sync" "No wallpaper found"
    exit 1
fi

# 2. Run Matugen
# We add -v to ensure it's actually doing work
matugen image "$WALLPAPER" --source-color-index 0

# 3. Wait for the file to actually update (Crucial for Bore kernel speed)
sleep 0.2

# 4. Pull colors with a fallback
CONF="$HOME/.cache/skwd-wall/hyprland-colors.conf"

# 29-31: Fixed sed patterns to include the '$' and allow for different spacing
C1=$(sed -n 's/.*\$color1 = //p' "$CONF" | tr -d '[:space:]')
C4=$(sed -n 's/.*\$color4 = //p' "$CONF" | tr -d '[:space:]')
C_INACTIVE=$(sed -n 's/.*\$inactive = //p' "$CONF" | tr -d '[:space:]')

# 33-39: Enhanced Fallbacks & Application
# This ensures that if the 'sed' fails, it uses your preferred palette instead of breaking
[ -z "$C1" ] && C1="rgba(baeaffff)"
[ -z "$C4" ] && C4="rgba(89d0edff)"
[ -z "$C_INACTIVE" ] && C_INACTIVE="rgba(0a0f11aa)"

# Apply directly to Hyprland
hyprctl keyword general:col.active_border "$C4 $C1 45deg"
hyprctl keyword general:col.inactive_border "$C_INACTIVE"

# 6. UI Refresh
pkill -USR1 kitty
swaync-client -rs
killall -SIGUSR2 caelestia 2>/dev/null
