########################################################################
##  SnowDots — SnowWallsync                             Version: v1.0.0    ##
##  Last Edited: 2026-04-29                                           ##
########################################################################

#!/bin/bash

# 1. Fidelity + Saturation (The Lucy-approved base)
RAW_JSON=$(matugen image --mode dark --type scheme-fidelity --prefer saturation "$1" --json hex)

# 2. Primary & Secondary (The most 'accurate' duo)
C1=$(echo "$RAW_JSON" | jq -r '.colors.primary.dark.color' | tr -d '#')
C2=$(echo "$RAW_JSON" | jq -r '.colors.secondary.dark.color' | tr -d '#')
C_INACTIVE=$(echo "$RAW_JSON" | jq -r '.colors.surface_variant.dark.color' | tr -d '#')

# 3. Fallbacks
[ "$C1" == "null" ] || [ -z "$C1" ] && C1="ffffff"
[ "$C2" == "null" ] || [ -z "$C2" ] && C2="444444"
[ "$C_INACTIVE" == "null" ] || [ -z "$C_INACTIVE" ] && C_INACTIVE="222222"

# 4. Atomic Write
mkdir -p ~/.cache/hypr
printf "\$color1 = 0xff%s\n\$color2 = 0xff%s\n\$inactive = 0xff%s\n" "$C1" "$C2" "$C_INACTIVE" > ~/.cache/hypr/colors.conf.tmp
mv ~/.cache/hypr/colors.conf.tmp ~/.cache/hypr/colors.conf

# 5. Apply
hyprctl keyword general:col.active_border "0xff$C1 0xff$C2 45deg"
hyprctl keyword general:col.inactive_border "0xff$C_INACTIVE"
