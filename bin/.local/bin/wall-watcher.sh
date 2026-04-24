#!/bin/bash

# Path to your sync script
SYNC_SCRIPT="$HOME/.local/bin/wall-sync.sh"

# Initialize variables
LAST_WALL="NONE"

echo "Watcher started: Monitoring awww..."

# Give the system 2 seconds to settle after login
sleep 2

# --- INITIAL RUN ON BOOT ---
# This forces the colors to match the current wallpaper immediately
CURRENT_WALL=$(awww query | awk -F ": " '{print $NF}' | xargs)
if [[ -f "$CURRENT_WALL" ]]; then
    echo "Initial sync for: $CURRENT_WALL"
    bash "$SYNC_SCRIPT" "$CURRENT_WALL"
    LAST_WALL="$CURRENT_WALL"
fi

# --- MONITORING LOOP ---
while true; do
    # 1. Ask awww for the current wallpaper path
    CURRENT_WALL=$(awww query | awk -F ": " '{print $NF}' | xargs)

    # 2. Check if it changed and is a valid file
    if [[ -n "$CURRENT_WALL" && "$CURRENT_WALL" != "$LAST_WALL" ]]; then
        if [ -f "$CURRENT_WALL" ]; then
            echo "Wallpaper change detected: $CURRENT_WALL"
            
            # Run the sync script
            bash "$SYNC_SCRIPT" "$CURRENT_WALL"
            
            # Update the tracker
            LAST_WALL="$CURRENT_WALL"
        fi
    fi
    
    # 3. Sleep to save CPU
    sleep 2
done
