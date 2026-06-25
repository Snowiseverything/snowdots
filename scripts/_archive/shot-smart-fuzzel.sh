########################################################################
##  SnowDots — SnowShotsmartfuzzel                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/bin/bash
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP=$(date +'%Y-%m-%d-%H%M%S')
FILE="$SAVE_DIR/screenshot_$TIMESTAMP.png"

# Capture Logic
case "$1" in
    region) grim -g "$(slurp)" "$FILE" ;;
    window) grim -g "$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$FILE" ;;
    full)   grim "$FILE" ;;
esac

[ ! -f "$FILE" ] && exit 1

# Auto-copy to clipboard
wl-copy < "$FILE"

# Fuzzel Menu
CHOICE=$(echo -e "󰏫 Edit\n󰝰 Open Folder\n󰆴 Delete" | fuzzel --dmenu -p "Action: ")

case "$CHOICE" in
    *"Edit")        swappy -f "$FILE" ;;
    *"Open Folder") xdg-open "$SAVE_DIR" ;;
    *"Delete")      rm "$FILE" ;;
esac
