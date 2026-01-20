#!/usr/bin/env bash

# Get current volume
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "yes" || echo "no")

# Create visual bar (20 chars max for good fit)
BARS=$((VOLUME / 5))
EMPTY=$((20 - BARS))
BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))

if [ "$MUTED" = "yes" ]; then
    DISPLAY="󰖁\nMuted"
else
    DISPLAY="$BAR\n$VOLUME%"
fi

# Use notify-osd for OSD-style popup (bottom-center)
gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.Notify "hyprarch" 0 "audio-volume-high" "Volume" "$DISPLAY" [] {} 1200 2>/dev/null || \
    notify-send -t 1200 "󰕾 Volume" "$DISPLAY" -h string:x-canonical-private-synchronous:volume
