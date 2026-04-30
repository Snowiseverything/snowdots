#!/bin/bash

# --- CONFIGURATION ---
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

TIMESTAMP=$(date +'%Y-%m-%d-%H%M%S')
FILE="$SAVE_DIR/screenshot_$TIMESTAMP.png"

# --- MODES ---
case "$1" in
    region)
        grim -g "$(slurp)" - | swappy -f - ;;
    window)
        grim -g "$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | swappy -f - ;;
    full)
        grim "$FILE"
        wl-copy < "$FILE"
        notify-send "󰄄 Screenshot" "Full screen captured" -i "$FILE" ;;
    *)
        echo "Usage: $0 {region|window|full}"
        exit 1 ;;
esac
