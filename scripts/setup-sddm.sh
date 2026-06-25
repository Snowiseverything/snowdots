#!/bin/bash
THEME_DIR=/usr/share/sddm/themes/silent
CONFIG_SRC=/home/snow/.cache/skwd-wall/sddm-silent.conf

cp "$CONFIG_SRC" "$THEME_DIR/configs/current.conf"
sed -i 's|^ConfigFile=.*|ConfigFile=configs/current.conf|' "$THEME_DIR/metadata.desktop"

echo "SDDM themed. Log out to see."
