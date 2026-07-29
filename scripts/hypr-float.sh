#!/bin/bash
#
#  SnowDots — SnowHyprfloat                             Version: v1.1.0
#  Last Edited: 2026-07-29
#

FLOAT=$(hyprctl activewindow -j | jq -r '.floating')
if [ "$FLOAT" = "true" ]; then
    hyprctl dispatch "hl.dsp.window.float()"
else
    # Count existing floating windows on current workspace for cascade
    WS=$(hyprctl activewindow -j | jq -r '.workspace.id')
    FLOAT_COUNT=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $WS and .floating == true)] | length")
    CASCADE=$((FLOAT_COUNT * 40))

    hyprctl dispatch "hl.dsp.window.float()"
    hyprctl dispatch "hl.dsp.window.center()"
    if [ "$CASCADE" -gt 0 ]; then
        hyprctl dispatch "hl.dsp.window.move({x = $CASCADE, y = $CASCADE})"
    fi
fi
