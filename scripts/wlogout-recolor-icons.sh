#!/usr/bin/env bash
set -euo pipefail

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"
SRC_DIR="$HOME/Dotfiles/wlogout/src-icons"
OUT_DIR="$HOME/Dotfiles/wlogout/icons"

if [ ! -f "$COLORS_FILE" ]; then
	echo "wlogout-recolor-icons: colors.json not found" >&2
	exit 1
fi

ACCENT=$(jq -r '.accent // empty' "$COLORS_FILE")
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ]; then
	echo "wlogout-recolor-icons: no accent color in $COLORS_FILE" >&2
	exit 1
fi

echo "wlogout-recolor-icons: coloring icons with $ACCENT"

mkdir -p "$OUT_DIR"

python3 -c "
import sys
import numpy as np
from PIL import Image
from pathlib import Path

accent = '$ACCENT'
r = int(accent[1:3], 16)
g = int(accent[3:5], 16)
b = int(accent[5:7], 16)
src_dir = Path('$SRC_DIR')
out_dir = Path('$OUT_DIR')

for name in ['power', 'lock', 'logout', 'restart', 'sleep']:
    src = src_dir / f'{name}.png'
    if not src.exists():
        continue

    img = Image.open(src).convert('RGBA')
    arr = np.array(img)
    alpha = arr[:,:,3].astype(float) / 255.0

    out = np.zeros((*arr.shape[:2], 4), dtype=np.uint8)
    out[:,:,0] = (alpha * r).astype(np.uint8)
    out[:,:,1] = (alpha * g).astype(np.uint8)
    out[:,:,2] = (alpha * b).astype(np.uint8)
    out[:,:,3] = arr[:,:,3]

    out_img = Image.fromarray(out)
    out_img.save(out_dir / f'{name}.png')
    out_img.save(out_dir / f'{name}-hover.png')
"

echo "wlogout-recolor-icons: done"
