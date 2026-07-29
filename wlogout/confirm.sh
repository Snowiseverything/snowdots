#!/usr/bin/env bash
action="$1"

# All actions get a zenity confirmation prompt
case "$action" in
lock)
	zenity --question --title="Lock" --text="Lock the session?" --width=300 --ok-label="Lock" --cancel-label="Cancel" 2>/dev/null
	[ $? -eq 0 ] && loginctl lock-session
	;;
sleep)
	zenity --question --title="Sleep" --text="Suspend the system?" --width=300 --ok-label="Suspend" --cancel-label="Cancel" 2>/dev/null
	[ $? -eq 0 ] && systemctl suspend
	;;
logout)
	zenity --question --title="Logout" --text="Terminate your session (close all apps)?" --width=350 --ok-label="Logout" --cancel-label="Cancel" 2>/dev/null
	[ $? -eq 0 ] && loginctl terminate-user "$USER"
	;;
shutdown)
	zenity --question --title="Shutdown" --text="Shut down the system?" --width=300 --ok-label="Shutdown" --cancel-label="Cancel" 2>/dev/null
	[ $? -eq 0 ] && systemctl poweroff
	;;
reboot)
	zenity --question --title="Reboot" --text="Reboot the system?" --width=300 --ok-label="Reboot" --cancel-label="Cancel" 2>/dev/null
	[ $? -eq 0 ] && systemctl reboot
	;;
esac
