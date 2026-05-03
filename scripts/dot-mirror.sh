#!/bin/bash
# SnowDots — Local Mirror Automation
DEST="/mnt/backups/Dotfiles-Mirror"

# Ensure the destination exists and is writable
if [ ! -d "$DEST" ]; then
    mkdir -p "$DEST"
fi

echo "💾 Mirroring Dotfiles to Local Storage: $DEST"

# -a: archive (keeps permissions), -v: verbose, --delete: stays identical to source
rsync -av --delete --exclude '.git' "$HOME/Dotfiles/" "$DEST/"

if [ $? -eq 0 ]; then
    notify-send "󰸉 Local Sync" "Mirror successful to /mnt/backups"
else
    notify-send "󱇧 Local Sync" "Mirror failed! Check permissions."
fi
