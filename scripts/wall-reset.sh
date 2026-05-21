#!/bin/bash
# ~/Dotfiles/scripts/wall-reset.sh
# Reset to current/last wallpaper - matugen post_processing handles color sync

# 1. Ensure services are running
pgrep awww-daemon > /dev/null || (rm -f $XDG_RUNTIME_DIR/awww.socket && awww-daemon --format xrgb &)
pgrep skwd-daemon > /dev/null || skwd &

# 2. Get current or last saved wallpaper
LAST_WALL_FILE="$HOME/.cache/skwd-wall/last_applied_wall.txt"
CURRENT=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | tr -d '[:space:]')

if [ -n "$CURRENT" ] && [ -f "$CURRENT" ] && [[ "$CURRENT" != *"lucy"* ]]; then
    TARGET="$CURRENT"
elif [ -f "$LAST_WALL_FILE" ]; then
    TARGET=$(cat "$LAST_WALL_FILE")
else
    TARGET="$HOME/Pictures/Wallpapers/272.webp"
fi

# 3. Save as last applied
mkdir -p "$HOME/.cache/skwd-wall"
echo "$TARGET" > "$LAST_WALL_FILE"

# 4. Set wallpaper
awww img "$TARGET" --transition-type wipe --transition-angle 30

# 5. Run matugen for color generation
matugen image "$TARGET" --source-color-index 0 2>/dev/null

# 6. Refresh RGB LEDs
bash "$HOME/Dotfiles/scripts/rgb-sync.sh" &>/dev/null

WALL_NAME=$(basename "$TARGET")
notify-send -i "$TARGET" "Wallpaper Changed" "Applied: $WALL_NAME" 2>/dev/null || true