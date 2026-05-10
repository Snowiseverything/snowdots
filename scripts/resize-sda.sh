#!/usr/bin/env bash
########################################################################
##  SnowDots — ResizeSda                             Version: v1.0.0    ##
##  Last Edited: 2026-05-10                                           ##
########################################################################
set -e

echo "==> Unmounting existing sda partitions..."
sudo umount /dev/sda1 /dev/sda2 /mnt/games /mnt/backups 2>/dev/null || true

# First resize sda1 (700G -> 650G)
echo "==> Resizing sda1 to 650GiB..."
sudo parted -s -f /dev/sda resizepart 1 650GiB

# Delete sda2 to recreate it in the new spot
echo "==> Re-creating sda2 (Backups) at 100GiB..."
sudo parted -s -f /dev/sda rm 2
sudo parted -s -f /dev/sda mkpart primary btrfs 650GiB 750GiB

# Create sda3 (Data) with the rest of the disk
echo "==> Creating sda3 (Data)..."
sudo parted -s -f /dev/sda mkpart primary btrfs 750GiB 931.5GiB

echo "==> Refreshing kernel partition table..."
sudo partprobe /dev/sda
sleep 2

echo "==> Formatting new partitions..."
sudo mkfs.btrfs -f -L backups /dev/sda2
sudo mkfs.btrfs -f -L data /dev/sda3

echo "==> DONE. Checking results..."
lsblk /dev/sda
