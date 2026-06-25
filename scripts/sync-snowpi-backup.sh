#!/bin/bash
# Sync Snowpi dotfiles backup from GitLab to /mnt/backups
set -e
cd /mnt/backups/snowpi-dotfiles.git
git fetch --all -q
echo "$(date): snowpi-dotfiles mirror synced"
