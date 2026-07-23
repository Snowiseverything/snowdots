#!/bin/bash
# Re-init snapper snapshot dirs
# Removes stale configs and creates fresh btrfs subvolumes

set -e

echo "=== Removing stale configs ==="
snapper -c root delete-config 2>/dev/null || true
snapper -c home delete-config 2>/dev/null || true

rm -rf /.snapshots /home/.snapshots 2>/dev/null || true

echo "=== Creating root config ==="
snapper -c root create-config /
snapper -c root set-config ALLOW_GROUPS="wheel" SYNC_ACL="no"
chmod 750 /.snapshots
chown :wheel /.snapshots

echo "=== Creating home config ==="
snapper -c home create-config /home
snapper -c home set-config ALLOW_GROUPS="wheel" SYNC_ACL="no"
chmod 750 /home/.snapshots
chown :wheel /home/.snapshots

echo "=== Verify ==="
snapper list-configs
ls -la /.snapshots /home/.snapshots

echo "Done. Try: sudo snapper -c root create -d 'test snapshot'"
