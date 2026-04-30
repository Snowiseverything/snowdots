#!/bin/bash

# --- CONFIGURATION ---
DOT_DIR="$HOME/Dotfiles"

# Function for Configuration Submenu
show_configs() {
    CONF_OPTIONS="󰘦 Hyprland\n󱁻 Kitty\n󱑖 Skwd Engine\n󰈺 Fish\n󰗊 Waybar\n󱁻 Wall-Sync\n󰕌 Back"
    CONF_CHOICE=$(echo -e "$CONF_OPTIONS" | fuzzel --dmenu --minimal-lines -p "Edit Configs: ")

    case "$CONF_CHOICE" in
        *Hyprland)   kitty -e nano "$DOT_DIR/hypr/.config/hypr/hyprland.conf" ;;
        *Kitty)      kitty -e nano "$DOT_DIR/kitty/.config/kitty/kitty.conf" ;;
        *Skwd*)      kitty -e nano "$HOME/.config/skwd-wall/config.json" ;;
        *Fish)       kitty -e nano "$DOT_DIR/fish/.config/fish/config.fish" ;;
        *Waybar)     kitty -e nano "$DOT_DIR/waybar/.config/waybar/config" ;;
        *Wall-Sync)  kitty -e nano "$DOT_DIR/fish/.config/fish/functions/ww-reload.fish" ;; # Point to the new logic
        *Back)       main_menu ;;
    esac
}

# Main Control Center
main_menu() {
    OPTIONS="󰷛 Lock\n󰏘 Wallpaper (Skwd)\n󰒓 Edit Configs...\n󱊑 Rice Fixer\n󰖔 Night Light\n󰖔 Suspend\n󰈆 Logout\n󰜉 Reboot\n󰐥 Shutdown"
    CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --minimal-lines -p "Control Center: ")

    case "$CHOICE" in
        *Lock) hyprlock ;;
        *Wallpaper) skwd wall toggle ;;
        *"Edit Configs"*) show_configs ;;
	*Rice*) 
            # 1. Safely restart the daemon
            killall skwd-daemon 2>/dev/null
            
            # 2. Prevent the "File Not Found" error
            # DO NOT DELETE the file, just ensure the directory exists
            mkdir -p ~/.cache/skwd-wall/
            if [ ! -f ~/.cache/skwd-wall/hyprland-colors.conf ]; then
                printf "\$color1 = rgba(baeaffff)\n\$color4 = rgba(89d0edff)\n\$inactive = rgba(0a0f11aa)\n" > ~/.cache/skwd-wall/hyprland-colors.conf
            fi
            
            # 3. Call the Master Engine
            # This triggers wall-sync.sh via your watcher
            fish -c "ww-reload"
            
            # 4. Restart Daemon and reload Hyprland to clear errors
            skwd-daemon & 
            sleep 0.2
            hyprctl reload
            
            notify-send "󱊑 Rice Fixer" "System Synced & Errors Cleared" ;;
        *"Night Light"*) "$HOME/.local/bin/sun-schedule.sh" toggle ;;
        *Suspend) 
            [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Suspend?") == *"Yes"* ]] && systemctl suspend ;;
        *Logout) 
            [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Logout?") == *"Yes"* ]] && hyprctl dispatch exit ;;
        *Reboot) 
            [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Reboot?") == *"Yes"* ]] && systemctl reboot ;;
        *Shutdown) 
            [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Shutdown?") == *"Yes"* ]] && systemctl poweroff ;;
    esac
}

main_menu
