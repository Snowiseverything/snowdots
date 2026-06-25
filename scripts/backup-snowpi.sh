#!/bin/bash
# Backup Snowpi system to /mnt/backups
set -e

SNOWPI="snow@192.168.1.35"
DEST="/mnt/backups/snowpi/system"
DATE=$(date +%Y%m%d_%H%M%S)
SNAPSHOT="$DEST/$DATE"
LATEST="$DEST/latest"

mkdir -p "$SNAPSHOT"

# Rsync system configs + home (exclude caches, tmp, transient)
rsync -aAX --delete \
  --link-dest="$LATEST" \
  --exclude={"/proc/*","/sys/*","/dev/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/var/cache/*","/var/log/*","/var/tmp/*","*.swap"} \
  "$SNOWPI:/" "$SNAPSHOT/"

# Save package list
ssh "$SNOWPI" 'dpkg --get-selections' > "$SNAPSHOT/package-list.txt"

# Save Docker image list
ssh "$SNOWPI" 'docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null' > "$SNAPSHOT/docker-images.txt"

# Remove old symlink and update
rm -f "$LATEST"
ln -s "$DATE" "$LATEST"

# Keep last 7 snapshots
ls -1d "$DEST"/[0-9]* | sort | head -n -7 | xargs -r rm -rf

echo "$(date): Snowpi backup complete -> $SNAPSHOT"
