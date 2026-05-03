#!/bin/bash

# 1. Start services
pgrep awww-daemon > /dev/null || (rm -f $XDG_RUNTIME_DIR/awww.socket && awww-daemon --format xrgb &)
pgrep skwd > /dev/null || skwd &

# 2. Get current or last saved
LAST_WALL_FILE="$HOME/.cache/skwd-wall/last_applied_wall.txt"
CURRENT=$(awww query | grep -oP 'image: \K.*' | tr -d '[:space:]')

if [ -n "$CURRENT" ] && [ -f "$CURRENT" ] && [[ "$CURRENT" != *"lucy"* ]]; then
    TARGET="$CURRENT"
elif [ -f "$LAST_WALL_FILE" ]; then
    TARGET=$(cat "$LAST_WALL_FILE")
else
    TARGET="$HOME/Pictures/Wallpapers/272.webp"
fi

# 3. Sync
~/Dotfiles/scripts/wall-sync.sh "$TARGET"
