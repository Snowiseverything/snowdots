########################################################################
##  SnowDots — Snowlauncher                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/bin/bash

CONFIG="$HOME/.cache/matugen/fuzzel-colors.ini"

if [ -f "$CONFIG" ]; then
    fuzzel --config "$CONFIG" --icon-theme="Papirus-Dark" --show-icons -p "󰣇  "
else
    fuzzel -p "󰣇  " --background-color "0a0f11dd" --text-color "baeaffff"
fi
