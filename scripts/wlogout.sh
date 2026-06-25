#!/usr/bin/env bash

if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

wlogout -C "$HOME/.config/wlogout/style.css" -l "$HOME/.config/wlogout/layout" --protocol layer-shell -b 5 -T 400 -B 400 &
