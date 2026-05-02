########################################################################
##  SnowDots — SnowWallwatcher                             Version: v1.0.0    ##
##  Last Edited: 2026-04-29                                           ##
########################################################################

#!/bin/bash

# Path to store the "last known" wallpaper
STATE_FILE="$HOME/.cache/skwd-wall/wallpaper/current.json"
mkdir -p "$(dirname "$STATE_FILE")"

# Initialize the last wallpaper variable
LAST_WALL=""
if [ -f "$STATE_FILE" ]; then
    LAST_WALL=$(jq -r '.path' "$STATE_FILE")
fi

echo "Loop Watcher started. Checking for wallpaper changes every second..."

while true; do
    # Ask awww-daemon directly for the current image
    CURRENT_WALL=$(awww query | sed -n 's/.*image: //p' | xargs)

    # If the wallpaper has changed and isn't empty
    if [ -n "$CURRENT_WALL" ] && [ "$CURRENT_WALL" != "$LAST_WALL" ]; then
        echo "Change detected: $CURRENT_WALL"
        
        # Update the state file
        echo "{\"path\": \"$CURRENT_WALL\"}" > "$STATE_FILE"
        
        # Trigger the sync script
        bash "$HOME/.local/bin/wall-sync.sh" "$CURRENT_WALL"
        
        # Update our tracking variable
        LAST_WALL="$CURRENT_WALL"
    fi

    # Check once per second
    sleep 1
done
