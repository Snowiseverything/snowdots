#!/bin/bash
# Freezer maintenance script - run with sudo
# Run: sudo bash ~/scripts/freezer-maintenance.sh

set -e

echo "=== 1. System Update ==="
pacman -Syu

echo "=== 2. Remove Orphans ==="
orphans=$(pacman -Qdtq)
if [ -n "$orphans" ]; then
  pacman -Rns $orphans
else
  echo "no orphans"
fi

echo "=== 3. Clean Pacman Cache (keep last 2 versions) ==="
paccache -rk2

echo "=== 4. Btrfs Scrubs ==="
btrfs scrub start /
btrfs scrub start /home
btrfs scrub start /mnt/backups
btrfs scrub start /mnt/data

echo "=== 5. Btrfs Balance (if space fragmented) ==="
btrfs balance start -dusage=50 /mnt/data 2>/dev/null || echo "balance not needed or skipping"

echo "=== 6. Status ==="
echo "Disk usage:"
df -h /
df -h /home
df -h /mnt/data
echo "fstrim timer:"
systemctl status fstrim.timer --no-pager | head -3
echo "Done."
