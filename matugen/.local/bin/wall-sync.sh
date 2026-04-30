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

# Use 'sed' instead of 'grep|awk' for cleaner parsing
C1=$(sed -n 's/.*color1 = //p' "$CONF" | tr -d '[:space:]')
C4=$(sed -n 's/.*color4 = //p' "$CONF" | tr -d '[:space:]')
C_INACTIVE=$(sed -n 's/.*inactive = //p' "$CONF" | tr -d '[:space:]')

# 5. Inject into Hyprland (Check if variables are empty before applying)
if [ -n "$C1" ] && [ -n "$C4" ]; then
    hyprctl keyword general:col.active_border "$C4 $C1 45deg"
    hyprctl keyword general:col.inactive_border "$C_INACTIVE"
else
    notify-send "wall-sync" "Color pull failed, keeping current"
fi

# 6. UI Refresh
pkill -USR1 kitty
swaync-client -rs
killall -SIGUSR2 caelestia 2>/dev/null
