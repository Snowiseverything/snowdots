#!/bin/bash
########################################################################
##  SnowDots — SnowFuzzelcontrol                             v1.1.5   ##
########################################################################

DOT_DIR="$HOME/Dotfiles"
SCRIPT_DIR="$DOT_DIR/scripts"

# Ensures all scripts are executable and snapshots the state before editing
ensure_executable() {
    find "$SCRIPT_DIR" -maxdepth 1 -type f \( -name "*.sh" -o ! -name "*.*" \) ! -executable -exec chmod +x {} +
}

edit_file() {
    # Safety first: Create a manual "Pre-Edit" snapshot on home
    notify-send "󰄬 Snapper" "Creating pre-edit snapshot..."
    sudo snapper -c home create --description "Pre-edit: $(basename "$1")"
    
    kitty -e nano "$1"
}

# --- MAIN MENU ---
main_menu() {
    ensure_executable
    OPTIONS="󰷛 Lock\n󰒓 Edit Configs...\n󱏟 Edit Scripts...\n󱏟 Run Scripts...\n󰅍 Copy Script...\n󰙨 Run Rice Fixer\n󰐥 Power Menu"
    CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --minimal-lines -p "Control Center: ")

    case "$CHOICE" in
        *Lock) loginctl lock-session ;;
        *"Edit Configs"*) show_configs ;;
        *"Edit Scripts"*) show_scripts ;;
        *"Run Scripts"*) run_scripts ;;
        *"Copy Script"*) copy_scripts ;;
        *"Run Rice Fixer"*) 
            killall skwd-daemon 2>/dev/null
            fish -c "ww-reload"
            skwd-daemon & hyprctl reload
            notify-send "󰙨 Rice Fixer" "System UI Refreshed" ;;
        *"Power Menu"*) power_menu ;;
    esac
}

# ... (Include the rest of the submenus from v1.1.4) ...

# --- EXECUTION ---
if [[ "$1" == "power" ]]; then
    power_menu
else
    main_menu
fi
