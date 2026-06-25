#!/bin/bash
# SnowDots — WallRenamer (safe: only renames non-sequential files)

WALL_DIR="$HOME/Pictures/Wallpapers"
cd "$WALL_DIR" || exit 1

# Max existing sequential number
max=0
for f in [0-9][0-9][0-9].*; do
    [ -f "$f" ] || continue
    n="${f%.*}"
    n=$((10#$n))
    [ "$n" -gt "$max" ] && max=$n
done

# Check if any non-sequential files exist
needs_rename=false
for f in *; do
    [ -f "$f" ] || continue
    [[ "$f" =~ ^[0-9]{3}\. ]] && continue
    needs_rename=true
    break
done

[ "$needs_rename" = false ] && echo "All files already sequential. No rename needed." && exit 0

# Stage non-sequential files in /tmp with new sequential names
TMP_STAGE=$(mktemp -d) || exit 1
trap 'rm -rf "$TMP_STAGE"' EXIT

counter=$((max + 1))
for f in *; do
    [ -f "$f" ] || continue
    [[ "$f" =~ ^[0-9]{3}\. ]] && continue
    ext="${f##*.}"
    new=$(printf "%03d.%s" "$counter" "$ext")
    cp "$f" "$TMP_STAGE/$new"
    ((counter++))
done

total=$((counter - max - 1))

# Remove original non-sequential files
for f in *; do
    [ -f "$f" ] || continue
    [[ "$f" =~ ^[0-9]{3}\. ]] && continue
    rm "$f"
done

# Move staged files back
mv "$TMP_STAGE"/* "$WALL_DIR"/ 2>/dev/null

echo "$total wallpapers renamed (existing sequential files kept)"
