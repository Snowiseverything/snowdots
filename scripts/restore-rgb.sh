#!/bin/sh
if [ "$1" = "pre" ]; then
    openrgb -d 0 -m off &>/dev/null
    openrgb -d 1 -m off &>/dev/null
    openrgb -d 2 -m off &>/dev/null
elif [ "$1" = "post" ]; then
    sleep 5
    sudo -u snow DISPLAY=:0 /home/snow/Dotfiles/scripts/rgb-sync.sh
fi
