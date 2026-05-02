########################################################################
##  SnowDots — SnowShotsmart                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/bin/bash

# --- CONFIGURATION ---
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP=$(date +'%Y-%m-%d-%H%M%S')
FILE="$SAVE_DIR/screenshot_$TIMESTAMP.png"

# --- CAPTURE LOGIC ---
case "$1" in
    region)
        grim -g "$(slurp)" "$FILE" ;;
    window)
        grim -g "$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$FILE" ;;
    full)
        grim "$FILE" ;;
    *)
        echo "Usage: $0 {region|window|full}"
        exit 1 ;;
esac

# Check if file was actually created (handles slurp escape)
if [ ! -f "$FILE" ]; then
    exit 1
fi

# Copy to clipboard
wl-copy < "$FILE"

# --- NOTIFICATION WITH ACTIONS ---
# This sends the notification and waits for a button click
ACTION=$(notify-send "󰄄 Screenshot Captured" "Saved to $(basename "$FILE")" \
    -i "$FILE" \
    --action="edit=󰏫 Edit" \
    --action="open=󰝰 Open Folder" \
    --action="delete=󰆴 Delete")

case "$ACTION" in
    "edit")
        swappy -f "$FILE" ;;
    "open")
        xdg-open "$SAVE_DIR" ;;
    "delete")
        rm "$FILE" ;;
esac
