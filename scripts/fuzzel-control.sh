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

# Games launcher — two-level: pick launcher (Steam/Lutris/Heroic) then game.
# Reads ~/.config/tui-games-launcher/games.toml; real cover-art icons via
# Rofi extended dmenu protocol (\0icon\x1f<path>).
games_parse() {
	# $1 = launcher filter (or "ALL"). Prints title|command|icon per game.
	awk -v L="$1" '
		function emit() {
			if (pt != "" && pc != "" && (L == "ALL" || pla == L))
				print pt "|" pc "|" pi
		}
		/^launcher =/ { emit(); pla=$0; sub(/^launcher = "/,"",pla); sub(/"$/,"",pla); pt=""; pc=""; pi="" }
		/^title =/   { pt=$0; sub(/^title = "/,"",pt); sub(/"$/,"",pt) }
		/^command =/ { pc=$0; sub(/^command = "/,"",pc); sub(/"$/,"",pc) }
		/^icon =/    { pi=$0; sub(/^icon = "/,"",pi); sub(/"$/,"",pi) }
		END { emit() }
	' "$GAMES_TOML"
}

open_games() {
	GAMES_TOML="$HOME/.config/tui-games-launcher/games.toml"
	[[ -f "$GAMES_TOML" ]] || {
		notify-send "󰊖 SnowDots" "games.toml not found"
		return
	}

	# Launcher metadata: name|icon-path|visible-if-games-exist
	# Steam uses fa-steam logo; Lutris/Heroic use their app icons.
	LAUNCHERS=(
		"Steam|/usr/share/icons/hicolor/256x256/apps/steam.png"
		"Lutris|/usr/share/icons/hicolor/128x128/apps/net.lutris.Lutris.png"
		"Heroic|/usr/share/icons/hicolor/128x128/apps/heroic.png"
	)

	# Level 1: pick launcher (only show launchers that have games)
	LIST=""
	for entry in "${LAUNCHERS[@]}"; do
		name="${entry%%|*}"
		icon="${entry#*|}"
		# count games for this launcher
		cnt=$(games_parse "${name,,}" | grep -c .)
		[[ "$cnt" -gt 0 ]] && LIST+="$name\0icon\x1f$icon\n"
	done
	LIST+="󰁍 Back"

	CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Games: ")
	[[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

	LAUNCHER="$(printf '%s' "$CHOICE" | tr '\0' '\n' | head -1)"
	LAUNCHER_LC="${LAUNCHER,,}"

	# Level 2: pick game within that launcher
	GLIST=""
	declare -A gcmds
	while IFS='|' read -r gtitle gcmd gicon; do
		[[ -z "$gtitle" ]] && continue
		gcmds["$gtitle"]="$gcmd"
		if [[ -n "$gicon" && -f "$gicon" ]]; then
			GLIST+="$gtitle\0icon\x1f$gicon\n"
		elif [[ -n "$gicon" ]]; then
			# text glyph icon (Nerd Font char) rendered inline; also key the
			# lookup by the prefixed form fuzzel returns on selection
			GLIST+="$gicon $gtitle\n"
			gcmds["$gicon $gtitle"]="$gcmd"
		else
			GLIST+="$gtitle\n"
		fi
	done < <(games_parse "$LAUNCHER_LC")
	GLIST+="󰁍 Back"

	GCHOICE=$(echo -e "$GLIST" | fuzzel --dmenu --minimal-lines -p "$LAUNCHER: ")
	[[ -z "$GCHOICE" || "$GCHOICE" == *"Back"* ]] && open_games && return

	GTITLE="$(printf '%s' "$GCHOICE" | tr '\0' '\n' | head -1)"
	GCMD="${gcmds[$GTITLE]}"
	if [[ -n "$GCMD" ]]; then
		hyprctl dispatch "hl.dsp.exec_cmd(\"$GCMD\")"
	else
		notify-send "󰊖 SnowDots" "No launch command for $GTITLE"
	fi
}

# Nested menu: Edit Configs / Edit Scripts / Run Scripts / Copy Script
edit_tools() {
	OPTIONS="󰘮 Edit Configs
 Edit Scripts
󰐊 Run Scripts
 Copy Script
󰁍 Back"
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
	OPTIONS="󰌾 Lock\n Search & Open\n󰊖 Folders\n Edit Configs/Scripts\n󰊖 Games\n󱌣 Run Rice Fixer\n󰐥 Power Menu\n⬇ Video Download"
	CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --minimal-lines -p "Control Center: ")

	case "$CHOICE" in
	*Lock) quickshell -c caelestia ipc call lock lock ;;
	*"Search & Open") search_open ;;
	*Folders) open_folders ;;
	*"Edit Configs/Scripts") edit_tools ;;
	*"Games") open_games ;;
	*"Run Rice Fixer")
		killall skwd-daemon 2>/dev/null
		fish -c "ww-reload"
		skwd-daemon &
		hyprctl reload
		notify-send "󱌣 Rice Fixer" "System UI Refreshed"
		;;
	*"Video Download") $HOME/Dotfiles/scripts/video-dl.sh ;;
	*"Power Menu") power_menu ;;
	esac
}

# --- FOLDERS (Nerd Font glyph icons) ---
open_folders() {
	LIST="󰎁 Videos
󰇚 Downloads
󰋩 Pictures
󰝚 Music
󰈙 Documents
󰍹 Desktop
󰋜 Home
󰉗 Custom Path…
󰁍 Back"

	CHOICE=$(echo -e "$LIST" | fuzzel --dmenu --minimal-lines -p "Open Folder: ")
	[[ -z "$CHOICE" || "$CHOICE" == *"Back"* ]] && main_menu && return

	if [[ "$CHOICE" == *"Custom Path…"* ]]; then
		PATH_IN=$(fuzzel --dmenu --lines=1 -p "Path: " \
			--placeholder "/home/snow/… (Tab to autocomplete)")
		[[ -z "$PATH_IN" ]] && main_menu && return
		PATH_IN=$(eval echo "$PATH_IN")
		if [[ -d "$PATH_IN" ]]; then
			xdg-open "$PATH_IN"
		else
			notify-send "󰊖 Folders" "Not a directory: $PATH_IN" || true
		fi
	else
		case "$CHOICE" in
		*Videos) xdg-open "$HOME/Videos" ;;
		*Downloads) xdg-open "$HOME/Downloads" ;;
		*Pictures) xdg-open "$HOME/Pictures" ;;
		*Music) xdg-open "$HOME/Music" ;;
		*Documents) xdg-open "$HOME/Documents" ;;
		*Desktop) xdg-open "$HOME/Desktop" ;;
		*Home) xdg-open "$HOME" ;;
		esac
	fi
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
		["rename-wallpapers.sh"]="󰸉 Rename Wallpapers"
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
