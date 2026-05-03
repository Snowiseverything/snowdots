#!/bin/bash
########################################################################
##  SnowDots — System Mirror                                 v1.0.2   ##
########################################################################

DEST="/mnt/backups/System-Mirror"

# Ensure backup directory ownership
if [ ! -d "$DEST" ]; then
    sudo mkdir -p "$DEST"
    sudo chown -R $USER:$USER /mnt/backups
fi

echo "💾 Mirroring Critical System & Dotfiles to /mnt/backups..."

# 1. Mirror Dotfiles (Home)
rsync -av --delete --exclude '.git' "$HOME/Dotfiles/" "$DEST/home-dots/"

# 2. Mirror Critical Root Configs (Check if files exist first)
FILES_TO_SYNC=""
for f in /etc/fstab /etc/default/grub /etc/mkinitcpio.conf /etc/pacman.conf; do
    [ -f "$f" ] && FILES_TO_SYNC+="$f "
done

if [ -n "$FILES_TO_SYNC" ]; then
    # This will now work without a password if visudo was updated
    sudo rsync -av --delete $FILES_TO_SYNC "$DEST/root-configs/"
fi

notify-send "󰸉 Mirror Complete" "System & Dotfiles synced to /mnt/backups"
