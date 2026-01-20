#!/usr/bin/env bash

choice=$(printf "Suspend\nShutdown\nReboot\nLogout" | fuzzel -d)

case "$choice" in
    Suspend)
        systemctl suspend
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    Reboot)
        systemctl reboot
        ;;
    Logout)
        hyprctl dispatch exit
        ;;
esac
