########################################################################
##  SnowDots — SnowFuzzelcontrol                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/bin/bash

# --- CONFIGURATION ---
DOT_DIR="$HOME/Dotfiles"
SCRIPT_DIR="$DOT_DIR/scripts"

# --- HELPER: EDIT FUNCTION ---
# Opens a file in a new kitty terminal using nano
edit_file() {
    kitty -e nano "$1"
}

# --- 1. MAIN MENU ---
main_menu() {
    OPTIONS="󰷛 Lock\n󰒓 Edit Configs...\n󱏟 Edit Scripts...\n󱏟 Run Scripts...\n󰙨 Run Rice Fixer\n󰖔 Night Light\n󰖔 Suspend\n󰈆 Logout\n󰜉 Reboot\n󰐥 Shutdown"
    CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --minimal-lines -p "Control Center: ")

    case "$CHOICE" in
        *Lock) loginctl lock-session ;;
        *"Edit Configs"*) show_configs ;;
        *"Edit Scripts"*) show_scripts ;;
        *"Run Scripts"*) run_scripts ;;
        *"Run Rice Fixer"*) 
            killall skwd-daemon 2>/dev/null
            mkdir -p ~/.cache/skwd-wall/
            fish -c "ww-reload"
            skwd-daemon & 
            hyprctl reload
            notify-send "󰙨 Rice Fixer" "System UI Refreshed" ;;
		*"Night Light"*) "$HOME/Dotfiles/scripts/night-light.sh" ;;
        *Suspend) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Suspend?") == *"Yes"* ]] && systemctl suspend ;;
        *Logout) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Logout?") == *"Yes"* ]] && hyprctl dispatch exit ;;
        *Reboot) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Reboot?") == *"Yes"* ]] && systemctl reboot ;;
        *Shutdown) [[ $(echo -e "󰄬 Yes\n󰏐 No" | fuzzel --dmenu --minimal-lines -p "Shutdown?") == *"Yes"* ]] && systemctl poweroff ;;
    esac
}

# --- SUBMENU: EDIT CONFIGS ---
show_configs() {
    declare -A configs
    configs=(
        ["󰘦 Hyprland"]="$DOT_DIR/hypr/.config/hypr/hyprland.conf"
        ["󰈺 Fish"]="$DOT_DIR/fish/.config/fish/config.fish"
        ["󱁻 Kitty"]="$DOT_DIR/kitty/.config/kitty/kitty.conf"
        ["󰗊 Waybar"]="$DOT_DIR/waybar/.config/waybar/config"
        ["󱁻 Wall-Sync"]="$DOT_DIR/fish/.config/fish/functions/ww-reload.fish"
        ["󱑖 Skwd Engine"]="$HOME/.config/skwd-wall/config.json"
    )

    # Manually listing keys in the printf command to force order
    CHOICE=$(printf "%s\n" "󰘦 Hyprland" "󰈺 Fish" "󱁻 Kitty" "󰗊 Waybar" "󱁻 Wall-Sync" "󱑖 Skwd Engine" "󰕌 Back" | fuzzel --dmenu --minimal-lines -p "Edit Configs: ")

    [[ "$CHOICE" == "󰕌 Back" || -z "$CHOICE" ]] && main_menu
    [[ -n "${configs[$CHOICE]}" ]] && edit_file "${configs[$CHOICE]}"
}

# --- SUBMENU: EDIT SCRIPTS ---
show_scripts() {
    declare -A scripts
    scripts=(
        ["󰚰 Dotfile Sync"]="$SCRIPT_DIR/dotsync"
        ["󰚮 Dotfile Pull"]="$SCRIPT_DIR/dotpull"
        ["󱇧 Edit Fuzzel-Menu"]="$SCRIPT_DIR/fuzzel-control.sh"
        ["󰷛 Integrity Check"]="$DOT_DIR/bin/check-dots.fish"
        [" Fix-Me System"]="$SCRIPT_DIR/fix-me.sh"
        ["󰖔 Sun Schedule"]="$SCRIPT_DIR/sun-schedule.sh"
    )

    CHOICE=$(printf "%s\n" "󰚰 Dotfile Sync" "󰚮 Dotfile Pull" "󱇧 Edit Fuzzel-Menu" "󰷛 Integrity Check" " Fix-Me System" "󰖔 Sun Schedule" "󰕌 Back" | fuzzel --dmenu --minimal-lines -p "Edit Scripts: ")

    [[ "$CHOICE" == "󰕌 Back" || -z "$CHOICE" ]] && main_menu
    [[ -n "${scripts[$CHOICE]}" ]] && edit_file "${scripts[$CHOICE]}"
}

# --- SUBMENU: RUN SCRIPTS ---
run_scripts() {
    # Define your list with icons manually to keep the SnowDots look
    # Format: "Icon Name|filename"
    LIST="󰚰 Sync Dotfiles|dotsync\n󰚮 Pull Dotfiles|dotpull\n Fix-Me System|fix-me.sh\n󰖔 Sun Schedule|sun-schedule.sh\n󰖔 Night Light|night-light.sh\n󰕌 Back|"
    
    # Show the "Icon Name" to the user
    CHOICE=$(echo -e "$LIST" | cut -d'|' -f1 | fuzzel --dmenu --minimal-lines -p "Run Script: ")

    # Exit if Back or nothing is selected
    [[ "$CHOICE" == *"Back"* || -z "$CHOICE" ]] && main_menu

    # Find the corresponding filename for the chosen icon
    FILE=$(echo -e "$LIST" | grep "$CHOICE" | cut -d'|' -f2)

    case "$FILE" in
        "dotsync"|"dotpull"|"fix-me.sh")
            notify-send "🚀 SnowDots" "Executing $FILE..."
            kitty -e bash -c "$SCRIPT_DIR/$FILE; echo; echo 'Task Complete. Press any key...'; read -n 1" ;;
        "night-light.sh")
            bash "$SCRIPT_DIR/$FILE" ;;
        *)
            bash "$SCRIPT_DIR/$FILE" &
            notify-send "󱆃 SnowDots" "Running $FILE" ;;
    esac
}

# --- EXECUTION ---
main_menu
