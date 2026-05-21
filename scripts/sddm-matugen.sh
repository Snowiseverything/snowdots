#!/bin/bash
# sddm-matugen.sh - Apply matugen colors to SDDM silent theme
set -euo pipefail

COLORS="$HOME/.config/skwd-wall/colors.json"
TEMPLATE="/usr/share/sddm/themes/silent/configs/catppuccin-mocha.conf"
CONFIG_FILE="$HOME/.cache/sddm-matugen.conf"
SYMLINK_TARGET="/usr/share/sddm/themes/silent/configs/default.conf"

# If symlink doesn't exist, try to create it (will work if user has write perms, else skip)
if [ ! -L "$SYMLINK_TARGET" ]; then
    ln -sf "$CONFIG_FILE" "$SYMLINK_TARGET" 2>/dev/null || true
fi

# Fallback colors if matugen not available
ACCENT="${1:-#89b4fa}"
BG="${2:-#1e1e2e}"
FG="${3:-#cdd6f4}"

if [ -f "$COLORS" ]; then
    ACCENT=$(jq -r '.accent // "#89b4fa"' "$COLORS")
    BG=$(jq -r '.background // "#1e1e2e"' "$COLORS")
    FG=$(jq -r '.foreground // "#cdd6f4"' "$COLORS")
fi

# Surface color (slightly lighter than background)
SURFACE=$(python3 -c "
c='$BG'.lstrip('#')
r,g,b=int(c[0:2],16),int(c[2:4],16),int(c[4:6],16)
r=min(255,int(r*1.15)); g=min(255,int(g*1.15)); b=min(255,int(b*1.15))
print(f'#{r:02x}{g:02x}{b:02x}')
")

# Generate config from template
sed -e "s/#1e1e2e/$BG/g" \
    -e "s/#cdd6f4/$FG/g" \
    -e "s/#89b4fa/$ACCENT/g" \
    -e "s/#74c7ec/$ACCENT/g" \
    -e "s/#89dceb/$ACCENT/g" \
    -e "s/#313244/$SURFACE/g" \
    -e "s/#45475a/$SURFACE/g" \
    "$TEMPLATE" > "$CONFIG_FILE"

