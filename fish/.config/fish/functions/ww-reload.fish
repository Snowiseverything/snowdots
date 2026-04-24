function ww-reload
    # ❄️ Snow's Master Sync
    set current_wall (swww query | awk -F 'image: ' '{print $2}')

    if test -n "$current_wall"
        # 1. Update Matugen Colors
        matugen image "$current_wall"
        
        # 2. Sync to the skwd-wall cache (The file Hyprland sources)
        # We ensure this file exists so Hyprland doesn't 'bonk' on reload
        mkdir -p ~/.cache/skwd-wall
        cp ~/.cache/matugen/colors-hyprland.conf ~/.cache/skwd-wall/hyprland-colors.conf 2>/dev/null

        # 3. Reload everything once
        hyprctl reload
        pkill -USR2 waybar
        
        notify-send "Rice Sync" "System updated for: "(basename "$current_wall") -i "$current_wall"
    else
        notify-send "Error" "No wallpaper detected by swww"
    end
end
