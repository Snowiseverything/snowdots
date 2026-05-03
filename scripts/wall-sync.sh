#!/bin/bash

########################################################################
##  SnowDots — SnowWallsync                               Version: v1.1.0 ##
##  Last Edited: 2026-05-03                                            ##
########################################################################

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
SKWD_JSON="$CACHE_DIR/wallpaper/current.json"

# Ensure the cache directory exists
mkdir -p "$CACHE_DIR"

# 3. Determine Wallpaper Path
# Priority Order:
# 1. Argument ($1)
# 2. Active Query (awww)
# 3. Persistent File (last_applied_wall.txt)
# 4. Final Fallback (272.webp)

if [ -n "$1" ] && [ -f "$1" ]; then
    WALLPAPER="$1"
else
    # Query the daemon for what is currently on screen
    WALLPAPER=$(awww query | grep -oP 'image: \K.*' | tr -d '[:space:]')
fi

# Apply the persistent fallback logic if the query failed or returned the Lucy default
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] || [[ "$WALLPAPER" == *"lucy"* ]]; then
    if [ -f "$LAST_WALL_FILE" ]; then
        WALLPAPER=$(cat "$LAST_WALL_FILE")
    else
        # The ultimate safety net based on your favorite current wall
        WALLPAPER="$HOME/Pictures/Wallpapers/272.webp"
    fi
fi

# 4. Save this as the "Last Known Good"
# This ensures that on next boot, even if JSON/Daemon are empty, we know what you used last
echo "$WALLPAPER" > "$LAST_WALL_FILE"

# 5. Apply the Image
# We check if it's already set to prevent redundant transitions
CURRENT_ON_SCREEN=$(awww query | grep -oP 'image: \K.*' | tr -d '[:space:]')

if [ "$WALLPAPER" != "$CURRENT_ON_SCREEN" ]; then
    # Try awww first, fallback to swww if you are using specific monitor outputs
    awww img "$WALLPAPER" --transition-type wipe --transition-angle 30 || \
    swww img "$WALLPAPER" --outputs DP-2 --transition-type wipe --transition-angle 30
fi

# 6. Refresh Colors (Matugen)
# Uses your source-color-index 0 preference
matugen image "$WALLPAPER" --source-color-index 0
sleep 0.2

# 7. Pull & Apply Hyprland Borders
# We use the skwd-generated config as the color source
CONF="$CACHE_DIR/hyprland-colors.conf"

C1=$(sed -n 's/.*\$color1 = //p' "$CONF" | tr -d '[:space:]')
C4=$(sed -n 's/.*\$color4 = //p' "$CONF" | tr -d '[:space:]')
C_INACTIVE=$(sed -n 's/.*\$inactive = //p' "$CONF" | tr -d '[:space:]')

# Border Fallbacks if sed fails to find values
[ -z "$C1" ] && C1="rgba(baeaffff)"
[ -z "$C4" ] && C4="rgba(89d0edff)"
[ -z "$C_INACTIVE" ] && C_INACTIVE="rgba(0a0f11aa)"

# Apply directly to Hyprland without a full reload
hyprctl keyword general:col.active_border "$C4 $C1 45deg"
hyprctl keyword general:col.inactive_border "$C_INACTIVE"

# 8. UI Refresh
# Notifies Kitty and SwayNC to reload their colors
pkill -USR1 kitty
swaync-client -rs
killall -SIGUSR2 caelestia 2>/dev/null

echo "Sync successful: $(basename "$WALLPAPER")"
