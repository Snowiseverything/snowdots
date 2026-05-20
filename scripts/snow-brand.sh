#!/bin/bash
# --------------------------------------------------------------------------
# SnowBranding Iron v7 - Symlink-Aware & Safe
# --------------------------------------------------------------------------

REPOS=("$HOME/Freezer-Dotfiles" "$HOME/SnowPi-Dotfiles")

for REPO in "${REPOS[@]}"; do
    [ ! -d "$REPO" ] && continue
    cd "$REPO" || continue
    echo "❄️  Scanning $REPO..."

    # Exclude scripts and grep for actual files only
    git ls-files | grep -v "scripts/" | while read -r FILE; do
        FULL_PATH="$REPO/$FILE"
        
        # SAFETY CHECK: Skip if it's a symlink, directory, or doesn't exist
        [ -L "$FULL_PATH" ] && continue
        [ ! -f "$FULL_PATH" ] && continue
        
        if [[ "$FILE" =~ \.(conf|sh|lua|bashrc|yaml|fish|ini|nanorc)$ ]] || [[ "$FILE" == *"rc" ]]; then
            
            REAL_DATE=$(date -r "$FULL_PATH" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
            BN=$(basename "$FILE")

            case "$BN" in
                "hyprland.conf")   CODENAME="Hyprland Config" ;;
                "waybar.conf")     CODENAME="Waybar Config" ;;
                "config.fish")     CODENAME="Fish Config" ;;
                "hypridle.conf")   CODENAME="Hypridle Config" ;;
                "kitty.conf")      CODENAME="Kitty Config" ;;
                "colors-matugen.conf") CODENAME="Kitty Matugen Colors" ;;
                "skwd-theme.conf")    CODENAME="Kitty Skwd Theme" ;;
                "hyprland-colors.conf") CODENAME="Hyprland Matugen Colors" ;;
                "kitty-colors.conf")   CODENAME="Matugen Template" ;;
                *)                 
                    CLEAN=$(echo "$BN" | cut -d. -f1 | sed 's/[^a-zA-Z0-9]//g')
                    CODENAME="${CLEAN}" ;;
            esac

            if grep -q "SnowDots —" "$FULL_PATH"; then
                # Update existing header
                sed -i "2s|##  SnowDots — .* Version:|##  SnowDots — $CODENAME                             Version:|" "$FULL_PATH"
            else
                # Create new header safely
                TEMP=$(mktemp)
                {
                    echo "########################################################################"
                    echo "##  SnowDots - $CODENAME                                             ##"
                    echo "########################################################################"
                    echo ""
                    cat "$FULL_PATH"
                } > "$TEMP"
                
                touch -r "$FULL_PATH" "$TEMP"
                mv "$TEMP" "$FULL_PATH"
                echo "✅ Branded: $CODENAME"
            fi
        fi
    done
done
