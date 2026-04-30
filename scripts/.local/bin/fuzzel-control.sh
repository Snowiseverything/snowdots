#!/bin/bash

# --- CONFIGURATION ---
DOT_DIR="$HOME/Dotfiles"

# --- HELPER: EDIT FUNCTION ---
# Opens a file in a new kitty terminal using nano
edit_file() {
    kitty -e nano "$1"
}

# --- SUBMENU: EDIT CONFIGS ---
show_configs() {
    declare -A configs
    configs=(
        ["󰘦 Hyprland"]="$DOT_DIR/hypr/.config/hypr/hyprland.conf"
        ["󱁻 Kitty"]="$DOT_DIR/kitty/.config/kitty/kitty.conf"
        ["󱑖 Skwd Engine"]="$HOME/.config/skwd-wall/config.json"
        ["󰈺 Fish"]="$DOT_DIR/fish/.config/fish/config.fish"
        ["󰗊 Waybar"]="$DOT_DIR/waybar/.config/waybar/config"
        ["󱁻 Wall-Sync"]="$DOT_DIR/fish/.config/fish/functions/ww-reload.fish"
    )

    CHOICE=$(printf "%s\n" "${!configs[@]}" "󰕌 Back" | fuzzel --dmenu --minimal-lines -p "Edit Configs: ")

    [[ "$CHOICE" == "󰕌 Back" || -z "$CHOICE" ]] && main_menu
    [[ -n "${configs[$CHOICE]}" ]] && edit_file "${configs[$CHOICE]}"
}

# --- SUBMENU: EDIT SCRIPTS ---
show_scripts() {
    declare -A scripts
    scripts=(
        ["󱊑 Rice Fixer"]="$DOT_DIR/scripts/.local/bin/fuzzel-control.sh"
        ["󰷛 Integrity Check"]="$DOT_DIR/bin/check-dots.fish"
        [" Fix-Me System"]="$HOME/fix-me.sh"
        ["󰖔 Sun Schedule"]="$HOME/.local/bin/sun-schedule.sh"
    )

    CHOICE=$(printf "%s\n" "${!scripts[@]}" "󰕌 Back" | fuzzel --dmenu --minimal-lines -p "Edit Scripts: ")

    [[ "$CHOICE" == "󰕌 Back" || -z "$CHOICE" ]] && main_menu
    [[ -n "${scripts[$CHOICE]}" ]] && edit_file "${scripts[$CHOICE]}"
}

# --- MAIN MENU ---
main_menu() {
    OPTIONS="󰷛 Lock\n󰏘 Wallpaper (Skwd)\n󰒓 Edit Configs...\n󱏟 Edit Scripts...\n󱊑 Run Rice Fixer\n󰖔 Night Light\n󰖔 Suspend\n󰈆 Logout\n󰜉 Reboot\n󰐥 Shutdown"
    CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --minimal-lines -p "Control Center: ")

    case "$CHOICE" in
        *Lock) loginctl lock-session ;;
        *Wallpaper) skwd wall toggle ;;
        *"Edit Configs"*) show_configs ;;
        *"Edit Scripts"*) show_scripts ;;
        *"Run Rice Fixer"*) 
            killall skwd-daemon 2>/dev/null
            mkdir -p ~/.cache/skwd-wall/
            fish -c "ww-reload"
            skwd-daemon & 
            hyprctl reload
            notify-send "󱊑 Rice Fixer" "System Synced" ;;
        *"Night Light"*) "$HOME/.local/bin/sun-schedule.sh" toggle ;;
        *Suspend) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Suspend?") == *"Yes"* ]] && systemctl suspend ;;
        *Logout) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Logout?") == *"Yes"* ]] && hyprctl dispatch exit ;;
        *Reboot) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Reboot?") == *"Yes"* ]] && systemctl reboot ;;
        *Shutdown) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Shutdown?") == *"Yes"* ]] && systemctl poweroff ;;
    esac
}

main_menu
