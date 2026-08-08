#!/bin/bash
########################################################################
##  SnowDots — SnowFuzzelcontrol                             v1.3.1   ##
########################################################################

DOT_DIR="$HOME/Dotfiles"
SCRIPT_DIR="$DOT_DIR/scripts"

# Ensures all scripts are executable
ensure_executable() {
	find "$SCRIPT_DIR" -maxdepth 1 -type f \( -name "*.sh" -o ! -name "*.*" \) ! -executable -exec chmod +x {} +
}

edit_file() {
	# We removed the snapper create command here to avoid hangs.
	# dotsync will handle the backup to GitLab and the SSD mirror later.
	# Hyprland 0.55+ (Lua config) broke `hyprctl dispatch exec "..."`
	# legacy syntax — must use the hl.dsp.exec_cmd() form now.
	hyprctl dispatch "hl.dsp.exec_cmd(\"kitty nano $1\")"
}

# All script files in SCRIPT_DIR (filenames only, no dirs)
script_files() {
	find "$SCRIPT_DIR" -maxdepth 1 -type f -printf '%f\n' | sort
}

# Games launcher — reads ~/.config/tui-games-launcher/games.toml, launches via fuzzel
# (games only; no terminal window, games run directly via Hyprland exec)
open_games() {
	GAMES_TOML="$HOME/.config/tui-games-launcher/games.toml"
	[[ -f "$GAMES_TOML" ]] || {
		notify-send "󰊖 SnowDots" "games.toml not found"
		return
	}

	declare -A gcmds
	LIST=""
	while IFS='|' read -r gtitle gcmd gicon; do
		[[ -z "$gtitle" ]] && continue
		gcmds["$gtitle"]="$gcmd"
		[[ -z "$gicon" ]] && gicon="󰊖"
		LIST+="$gicon $gtitle\n"
	done < <(awk '
		/^title =/ { if (t != "" && c != "") print t "|" c "|" i; t=$0; sub(/^title = "/,"",t); sub(/"$/,"",t); c=""; i="" }
		/^command =/ { c=$0; sub(/^command = "/,"",c); sub(/"$/,"",c) }
		/^icon =/ { i=$0; sub(/^icon = "/,"",i); sub(/"$/,"",i) }
		END { if (t != "" && c != "") print t "|" c "|" i }
	' "$GAMES_TOML")
	LIST+="󰜉 Back"

	CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Games: ")
	[[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

	GTITLE="${CHOICE#* }"
	GCMD="${gcmds[$GTITLE]}"
	if [[ -n "$GCMD" ]]; then
		hyprctl dispatch "hl.dsp.exec_cmd(\"$GCMD\")"
	else
		notify-send "󰊖 SnowDots" "No launch command for $GTITLE"
	fi
}

# Nested menu: Edit Configs / Edit Scripts / Run Scripts / Copy Script
edit_tools() {
	OPTIONS=" Edit Configs\n Edit Scripts\n Run Scripts\n Copy Script\n󰜉 Back"
	CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --minimal-lines -p "Edit Configs/Scripts: ")

	case "$CHOICE" in
	*"Edit Configs") show_configs ;;
	*"Edit Scripts") show_scripts ;;
	*"Run Scripts") run_scripts ;;
	*"Copy Script") copy_scripts ;;
	*) main_menu ;;
	esac
}

# --- MAIN MENU ---
main_menu() {
	ensure_executable
	OPTIONS="󰌾 Lock\n Search & Open\n Edit Configs/Scripts\n󰊖 Games\n󱌣 Run Rice Fixer\n󰐥 Power Menu"
	CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --minimal-lines -p "Control Center: ")

	case "$CHOICE" in
	*Lock) quickshell -c caelestia ipc call lock lock ;;
	*"Search & Open") search_open ;;
	*"Edit Configs/Scripts") edit_tools ;;
	*"Games") open_games ;;
	*"Run Rice Fixer")
		killall skwd-daemon 2>/dev/null
		fish -c "ww-reload"
		skwd-daemon &
		hyprctl reload
		notify-send "󱌣 Rice Fixer" "System UI Refreshed"
		;;
	*"Power Menu") power_menu ;;
	esac
}

# --- 2. DYNAMIC SUBMENUS ---

search_open() {
	declare -A paths
	paths=(
		["hyprland.conf"]="$DOT_DIR/hypr/hyprland.conf"
		["config.fish"]="$DOT_DIR/fish/config.fish"
		["kitty.conf"]="$DOT_DIR/kitty/kitty.conf"
		["starship.toml"]="$DOT_DIR/starship/starship.toml"
	)

	# Configs + scripts in one list — fuzzel filters live as you type
	LIST=$(
		for f in "${!paths[@]}"; do
			case "$f" in
			hyprland.conf) printf ' ' ;;
			config.fish) printf '󰈺 ' ;;
			kitty.conf) printf '󰄛 ' ;;
			starship.toml) printf ' ' ;;
			esac
			echo "$f"
		done
		for f in $(script_files); do
			echo "$(script_icon "$f") $f"
		done | sort
	)
	LIST+="\n Back"

	CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Search & Open: ")
	[[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

	CLEAN_NAME=$(echo "$CHOICE" | cut -d' ' -f2-)
	if [[ -n "${paths[$CLEAN_NAME]}" ]]; then
		edit_file "${paths[$CLEAN_NAME]}"
	else
		edit_file "$SCRIPT_DIR/$CLEAN_NAME"
	fi
}

run_scripts() {
	declare -A labels
	labels=(
		["dotsync"]="󰓦 Dotfile Sync"
		["dotpull"]="󰇚 Dotfile Pull"
		["fix-me.sh"]="󱌣 System Fixer"
		["sun-schedule.sh"]="󰖙 Sun Schedule"
		["night-light.sh"]="󰖔 Night Light"
		["app-launcher.sh"]="󰀻 App Launcher"
		["fuzzel-control.sh"]=" Control Center"
	)

	RAW_FILES=$(script_files)
	LIST=""
	for f in $RAW_FILES; do
		if [[ -n "${labels[$f]}" ]]; then
			LIST+="${labels[$f]}\n"
		fi
	done
	LIST+="\n Back"

	CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Run Script: ")
	[ $? -ne 0 ] && return
	[[ "$CHOICE" == *"Back"* ]] && main_menu && return

	FINAL_SCRIPT=""
	for f in "${!labels[@]}"; do
		if [[ "${labels[$f]}" == "$CHOICE" ]]; then
			FINAL_SCRIPT="$f"
			break
		fi
	done

	if [[ "$FINAL_SCRIPT" == "dotsync" || "$FINAL_SCRIPT" == "fix-me.sh" || "$FINAL_SCRIPT" == "dotpull" ]]; then
		kitty -e bash -c "$SCRIPT_DIR/$FINAL_SCRIPT; echo; read -n 1"
	else
		bash "$SCRIPT_DIR/$FINAL_SCRIPT" &
	fi
}

script_icon() {
	case "$1" in
	dotsync | dotpull) printf '󰓦' ;;
	fix-me.sh) printf '󱌣' ;;
	sun-schedule.sh) printf '󰖙' ;;
	night-light.sh) printf '󰖔' ;;
	app-launcher.sh) printf '󰀻' ;;
	fuzzel-control.sh) printf '' ;;
	*) printf '' ;;
	esac
}

show_scripts() {
	RAW_FILES=$(script_files)
	LIST=$(for f in $RAW_FILES; do echo -e "$(script_icon "$f") $f"; done)
	LIST+="\n Back"

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
	)

	LIST=$(for f in "${!paths[@]}"; do
		case "$f" in
		hyprland.conf) printf ' ' ;;
		config.fish) printf '󰈺 ' ;;
		kitty.conf) printf '󰄛 ' ;;
		starship.toml) printf ' ' ;;
		*) printf ' ' ;;
		esac
		echo "$f"
	done | sort)
	LIST+="\n Back"

	CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Edit Config: ")
	[[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

	CLEAN_NAME=$(echo "$CHOICE" | cut -d' ' -f2-)
	edit_file "${paths[$CLEAN_NAME]}"
}

copy_scripts() {
	RAW_FILES=$(script_files)
	LIST=$(for f in $RAW_FILES; do echo -e "$(script_icon "$f") $f"; done)
	LIST+="\n Back"

	CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Copy Script: ")
	[[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

	CLEAN_NAME=$(echo "$CHOICE" | cut -d' ' -f2-)
	cat "$SCRIPT_DIR/$CLEAN_NAME" | wl-copy
	notify-send " SnowDots" "$CLEAN_NAME copied to clipboard!"
}

# --- 3. POWER MENU ---
power_menu() {
	P_OPTIONS="󰒲 Suspend\n󰈆 Logout\n󰜉 Reboot\n󰐥 Shutdown\n Back"
	P_CHOICE=$(echo -e "$P_OPTIONS" | fuzzel --dmenu --minimal-lines -p "Power: ")
	[ $? -ne 0 ] && return
	[[ "$P_CHOICE" == *"Back"* ]] && main_menu && return

	CONFIRM=$(echo -e " Yes, $P_CHOICE\n󰅜 No, go back" | fuzzel --dmenu --minimal-lines -p "Confirm: ")
	[[ "$CONFIRM" != *"Yes"* ]] && return

	case "$P_CHOICE" in
	*Suspend) systemctl suspend ;;
	*Logout) hyprctl dispatch 'hl.dsp.exit()' ;;
	*Reboot) systemctl reboot ;;
	*Shutdown) systemctl poweroff ;;
	esac
}

# --- EXECUTION ---
if [[ "$1" == "power" ]]; then
	power_menu
else
	main_menu
fi
