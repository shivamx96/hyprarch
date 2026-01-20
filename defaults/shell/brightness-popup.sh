#!/usr/bin/env bash

# Get current brightness
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((BRIGHTNESS * 100 / MAX))

# Create visual bar (20 chars max for good fit)
BARS=$((PERCENT / 5))
EMPTY=$((20 - BARS))
BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))
DISPLAY="$BAR\n$PERCENT%"

# Use notify-osd for OSD-style popup (bottom-center)
gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.Notify "hyprarch" 0 "brightness-low" "Brightness" "$DISPLAY" [] {} 1200 2>/dev/null || \
    notify-send -t 1200 "󰃟 Brightness" "$DISPLAY" -h string:x-canonical-private-synchronous:brightness
