#!/usr/bin/env bash
action="$1"

case "$action" in
shutdown)
	zenity --question --title="Shutdown" --text="Shut down the system?" --width=300 --ok-label="Shutdown" --cancel-label="Cancel"
	if [ $? -eq 0 ]; then
		systemctl poweroff
	fi
	;;
reboot)
	zenity --question --title="Reboot" --text="Reboot the system?" --width=300 --ok-label="Reboot" --cancel-label="Cancel"
	if [ $? -eq 0 ]; then
		systemctl reboot
	fi
	;;
esac
