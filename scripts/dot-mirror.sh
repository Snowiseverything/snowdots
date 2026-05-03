#!/bin/bash
########################################################################
##  SnowDots — System Mirror                                 v1.0.1   ##
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

# 2. Mirror Critical Root Configs (The Life-Support Files)
sudo rsync -av --delete /etc/fstab /etc/default/grub /etc/mkinitcpio.conf /etc/pacman.conf "$DEST/root-configs/"

notify-send "󰸉 Mirror Complete" "System & Dotfiles synced to /mnt/backups"
