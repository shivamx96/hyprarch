#!/usr/bin/env bash

# Get current volume
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "yes" || echo "no")

# Create visual bar
BARS=$((VOLUME / 5))
EMPTY=$((20 - BARS))
BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))

if [ "$MUTED" = "yes" ]; then
    TEXT="Muted"
else
    TEXT="$BAR\n$VOLUME%"
fi

# Show notification via dunst
notify-send -t 1200 "󰕾 Volume" "$TEXT" -h string:x-canonical-private-synchronous:volume
