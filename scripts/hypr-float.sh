#!/bin/bash
#
#  SnowDots — SnowHyprfloat                             Version: v1.0.0
#  Last Edited: 2026-07-29
#

FLOAT=$(hyprctl activewindow -j | jq -r '.floating')
if [ "$FLOAT" = "true" ]; then
    hyprctl dispatch "hl.dsp.window.float()"
else
    hyprctl dispatch "hl.dsp.window.float()"
    hyprctl dispatch "hl.dsp.window.center()"
fi
