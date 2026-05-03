#!/bin/bash
########################################################################
##  SnowDots — SnowFuzzelcontrol                             v1.1.3   ##
########################################################################

DOT_DIR="$HOME/Dotfiles"
SCRIPT_DIR="$DOT_DIR/scripts"

# Opens a file in a new kitty terminal using nano
edit_file() {
    kitty -e nano "$1"
}

# --- 1. MAIN MENU ---
main_menu() {
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

# --- 2. DYNAMIC SUBMENUS ---

run_scripts() {
    declare -A labels
    # Only keep scripts you actually want to run from the menu
    labels=(
        ["dotsync"]="󰷛 Dotfile Sync"
        ["dotpull"]="󰷚 Dotfile Pull"
        ["fix-me.sh"]="󰙨 System Fixer"
        ["sun-schedule.sh"]="󰖙 Sun Schedule"
        ["night-light.sh"]="󰖔 Night Light"
        ["app-launcher.sh"]="󰀻 App Launcher"
        ["fuzzel-control.sh"]="󰒓 Control Center"
    )

    RAW_FILES=$(ls -p "$SCRIPT_DIR" | grep -v /)
    LIST=""
    for f in $RAW_FILES; do
        # Only show the script if it has a label (removes screenshot clutter)
        if [[ -n "${labels[$f]}" ]]; then 
            LIST+="${labels[$f]}\n"
        fi
    done
    LIST+="󰕌 Back"

    CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Run Script: ")
    [[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

    # Reverse lookup the filename
    FINAL_SCRIPT=""
    for f in "${!labels[@]}"; do
        if [[ "${labels[$f]}" == "$CHOICE" ]]; then FINAL_SCRIPT="$f"; break; fi
    done

    # --- SIMPLIFIED EXECUTION LOGIC ---
    if [[ "$FINAL_SCRIPT" == "dotsync" || "$FINAL_SCRIPT" == "fix-me.sh" || "$FINAL_SCRIPT" == "dotpull" ]]; then
        kitty -e bash -c "$SCRIPT_DIR/$FINAL_SCRIPT; echo; read -n 1"
    else
        bash "$SCRIPT_DIR/$FINAL_SCRIPT" &
    fi
}

show_scripts() {
    # Keeps all files visible for editing, including screenshot scripts
    RAW_FILES=$(ls -p "$SCRIPT_DIR" | grep -v /)
    LIST=$(for f in $RAW_FILES; do echo -e "󱏟 $f"; done)
    LIST+="\n󰕌 Back"

    CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Edit Script: ")
    [[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return
    
    CLEAN_NAME=$(echo "$CHOICE" | cut -d' ' -f2-)
    edit_file "$SCRIPT_DIR/$CLEAN_NAME"
}

show_configs() {
    declare -A paths
    paths=(
        ["hyprland.conf"]="$DOT_DIR/hypr/hyprland.conf"
        ["config.fish"]="$DOT_DIR/fish/config.fish"
        ["kitty.conf"]="$DOT_DIR/kitty/kitty.conf"
        ["starship.toml"]="$DOT_DIR/starship/starship.toml"
        ["waybar-config"]="$DOT_DIR/waybar/config"
    )

    LIST=$(for f in "${!paths[@]}"; do echo -e "󰒓 $f"; done | sort)
    LIST+="\n󰕌 Back"

    CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Edit Config: ")
    [[ "$CHOICE" == *"Back"* || -z "$CHOICE" ]] && main_menu && return

    CLEAN_NAME=$(echo "$CHOICE" | cut -d' ' -f2-)
    edit_file "${paths[$CLEAN_NAME]}"
}

copy_scripts() {
    # Keeps all files available for copying
    RAW_FILES=$(ls -p "$SCRIPT_DIR" | grep -v /)
    LIST=$(for f in $RAW_FILES; do echo -e "󰅍 $f"; done)
    LIST+="\n󰕌 Back"

    CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Copy Script: ")
    [[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

    CLEAN_NAME=$(echo "$CHOICE" | cut -d' ' -f2-)
    cat "$SCRIPT_DIR/$CLEAN_NAME" | wl-copy
    notify-send "󰅍 SnowDots" "$CLEAN_NAME copied to clipboard!"
}

# --- 3. POWER MENU ---
power_menu() {
    P_OPTIONS="󰒲 Suspend\n󰈆 Logout\n󰜉 Reboot\n󰐥 Shutdown\n󰕌 Back"
    P_CHOICE=$(echo -e "$P_OPTIONS" | fuzzel --dmenu --minimal-lines -p "Power: ")

    case "$P_CHOICE" in
        *Suspend) systemctl suspend ;;
        *Logout) hyprctl dispatch exit ;;
        *Reboot) systemctl reboot ;;
        *Shutdown) systemctl poweroff ;;
        *Back) main_menu ;;
    esac
}

# --- EXECUTION ---
if [[ "$1" == "power" ]]; then
    power_menu
else
    main_menu
fi
