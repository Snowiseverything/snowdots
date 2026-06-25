#!/bin/bash
# NP1 - Stock restore + lock script
# Run from /tmp/stock/

STOCK=/tmp/stock

echo "=== Step 1: Unlock bootloader ==="
fastboot flashing unlock
echo "Press Volume Up on phone to confirm unlock"
sleep 10

echo "=== Step 2: Flash boot to both slots ==="
fastboot flash boot_a "$STOCK/boot.img" && fastboot flash boot_b "$STOCK/boot.img"

echo "=== Step 3: Flash vbmeta to both slots (NO disable-verity) ==="
fastboot flash vbmeta_a "$STOCK/vbmeta.img" && fastboot flash vbmeta_b "$STOCK/vbmeta.img"

echo "=== Step 4: Flash dtbo + vendor_boot to both slots ==="
fastboot flash dtbo_a "$STOCK/dtbo.img" && fastboot flash dtbo_b "$STOCK/dtbo.img"
fastboot flash vendor_boot_a "$STOCK/vendor_boot.img" && fastboot flash vendor_boot_b "$STOCK/vendor_boot.img"

echo "=== Step 5: Flash firmware (what we can) ==="
cd "$STOCK/firmware"
for img in *.img; do
  base="${img%.img}"
  fastboot flash "${base}_a" "$img" 2>/dev/null
  fastboot flash "${base}_b" "$img" 2>/dev/null
done

echo "=== Step 6: Enter fastbootd for logical partitions ==="
fastboot reboot fastboot
sleep 10

echo "=== Step 7: Resize and flash logical partitions ==="
cd "$STOCK/logical"
for img in *.img; do
  base="${img%.img}"
  size=$(stat --format="%s" "$img")
  fastboot resize-logical-partition "${base}_a" "$size" 2>/dev/null
  fastboot flash "${base}_a" "$img"
done

echo "=== Step 8: Format data ==="
fastboot format userdata 2>/dev/null || fastboot erase userdata
fastboot erase cache 2>/dev/null

echo "=== Step 9: Reboot to system ==="
fastboot reboot

echo "=== DONE ==="
echo "Let device boot fully, then run: fastboot flashing lock"
echo "Confirm lock, then factory reset from recovery after lock."
