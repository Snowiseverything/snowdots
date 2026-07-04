#!/bin/bash
########################################################################
##  SnowDots — System Mirror                                 v1.0.4   ##
########################################################################

DEST="/mnt/backups/System-Mirror"
SNOWPI="snow@100.83.33.67"

# Ensure backup directory ownership
if [ ! -d "$DEST" ]; then
    sudo mkdir -p "$DEST"
    sudo chown -R $USER:$USER /mnt/backups
fi

echo "💾 SnowDots System Mirror — $(date)"

# 1. Dotfiles repo (lean, no .git)
rsync -av --delete --exclude '.git/' "$HOME/Dotfiles/" "$DEST/home-dots/"

# 2. Root configs
ROOT_CONFS=""
for f in /etc/fstab /etc/default/grub /etc/mkinitcpio.conf /etc/pacman.conf /etc/sddm.conf /etc/udev/rules.d /etc/modprobe.d /etc/systemd/network; do
  [ -e "$f" ] && ROOT_CONFS+="$f "
done
if [ -n "$ROOT_CONFS" ]; then
  sudo rsync -av --delete $ROOT_CONFS "$DEST/root-configs/"
fi

# 3. Local scripts & bins
rsync -av "$HOME/.local/bin/" "$DEST/local-bin/"

# 4. Systemd user services
rsync -av "$HOME/.config/systemd/user/" "$DEST/systemd-user/"

# 5. SSH (sensitive — local mirror only)
rsync -av "$HOME/.ssh/" "$DEST/ssh/"

# 6. Package list
pacman -Qn > "$DEST/pkglist.txt"
pacman -Qm >> "$DEST/pkglist-aur.txt"

# 7. Wallpapers (no delete — keep history)
rsync -av "$HOME/Pictures/Wallpapers/" "$DEST/wallpapers/"

# 8. Projects (git repos + uncommitted work)
rsync -av --delete \
  --exclude '.git/' --exclude 'node_modules/' --exclude 'target/' --exclude 'venv/' \
  "$HOME/Projects/" "$DEST/projects/"

# 9. OpenCode session DB backup
sqlite3 "$HOME/.local/share/opencode/opencode.db" \
  ".backup '$DEST/opencode-db-backup/opencode.db'" 2>/dev/null

# 10. Rsync critical sets to Snowpi for off-site
rsync -avz "$DEST/pkglist.txt" "$DEST/pkglist-aur.txt" \
  "$DEST/root-configs/" "$DEST/local-bin/" "$DEST/systemd-user/" \
  "$DEST/opencode-db-backup/" \
  "$SNOWPI:/mnt/backups/freezer-mirror/" 2>/dev/null || true

notify-send "󰸉 Mirror Complete" "System synced to /mnt/backups + Snowpi"
