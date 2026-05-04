#!/bin/bash 
###########################################################################
##  SnowDots — SnowWallsync                              Version: v1.1.2 ##
##  Last Edited: 2026-05-04                                              ##
###########################################################################

# 1. Daemon Check
# Ensures the socket is clean and awww is running before we proceed
if ! pgrep -x "awww-daemon" > /dev/null; then
    rm -f $XDG_RUNTIME_DIR/awww.socket
    awww-daemon --format xrgb &
    sleep 0.5
fi

# 2. Path Definitions
CACHE_DIR="$HOME/.cache/skwd-wall"
LAST_WALL_FILE="$CACHE_DIR/last_applied_wall.txt"
mkdir -p "$CACHE_DIR"

# 3. Determine Wallpaper Path
# Priority: Argument ($1) from Matugen > Awww Query > Last Known Good > Fallback
if [ -n "$1" ] && [ -f "$1" ]; then
    WALLPAPER="$1"
else
    WALLPAPER=$(awww query | grep -oP 'image: \K.*' | tr -d '[:space:]')
fi

# Apply fallback logic if query fails
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] || [[ "$WALLPAPER" == *"lucy"* ]]; then
    if [ -f "$LAST_WALL_FILE" ]; then
        WALLPAPER=$(cat "$LAST_WALL_FILE")
    else
        WALLPAPER="$HOME/Pictures/Wallpapers/272.webp"
    fi
fi

# Save as the "Last Known Good"
echo "$WALLPAPER" > "$LAST_WALL_FILE"

# 4. Apply the Image
# Only transitions if the wallpaper actually changed
CURRENT_ON_SCREEN=$(awww query | grep -oP 'image: \K.*' | tr -d '[:space:]')
if [ "$WALLPAPER" != "$CURRENT_ON_SCREEN" ]; then
    awww img "$WALLPAPER" --transition-type wipe --transition-angle 30 || \
    swww img "$WALLPAPER" --outputs DP-2 --transition-type wipe --transition-angle 30
fi

# 5. UI Refresh & Borders
# Refresh border colors directly from the generated skwd-wall cache
CONF="$CACHE_DIR/hyprland-colors.conf"
C1=$(sed -n 's/.*\$color1 = //p' "$CONF" | tr -d '[:space:]')
C4=$(sed -n 's/.*\$color4 = //p' "$CONF" | tr -d '[:space:]')
[ -n "$C1" ] && [ -n "$C4" ] && hyprctl keyword general:col.active_border "$C4 $C1 45deg"

# Notify Kitty via signal to reload its config
pkill -USR1 kitty

# SwayNC Reload
swaync-client -rs

# 6. Notification
WALL_NAME=$(basename "$WALLPAPER")
notify-send -i "$1" "Wallpaper Changed" "Applied: $(basename "$1")"

echo "Sync successful: $WALL_NAME"
