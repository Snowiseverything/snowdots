#!/bin/bash
# ~/Dotfiles/scripts/wall-reset.sh
# Reset to current/last wallpaper - matugen post_processing handles color sync

# 1. Ensure skwd is running
pgrep skwd-daemon > /dev/null || skwd &

# 2. Get current or last saved wallpaper
LAST_WALL_FILE="$HOME/.cache/skwd-wall/last_applied_wall.txt"

if [ -f "$LAST_WALL_FILE" ]; then
    TARGET=$(cat "$LAST_WALL_FILE")
else
    TARGET="$HOME/Pictures/Wallpapers/272.webp"
fi

# 4. Set wallpaper through skwd (triggers matugen + postProcessing automatically)
WALL_NAME=$(basename "$TARGET")
skwd wall import "{\"path\":\"$TARGET\"}" &>/dev/null
skwd wall apply "{\"name\":\"$WALL_NAME\"}" &>/dev/null

# 5. rgb-sync runs automatically via skwd postProcessing - no explicit call needed

WALL_NAME=$(basename "$TARGET")
notify-send -i "$TARGET" "Wallpaper Changed" "Applied: $WALL_NAME" 2>/dev/null || true