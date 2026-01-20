#!/usr/bin/env bash

# Get current volume
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "Muted" || echo "")

# Create volume bar
if [ "$MUTED" = "Muted" ]; then
    ICON="󰖁"
    TEXT="Volume: Muted"
else
    if [ "$VOLUME" -eq 0 ]; then
        ICON="󰕿"
    elif [ "$VOLUME" -lt 33 ]; then
        ICON="󰕿"
    elif [ "$VOLUME" -lt 66 ]; then
        ICON="󰖀"
    else
        ICON="󰕾"
    fi

    # Create visual bar
    BARS=$((VOLUME / 10))
    EMPTY=$((10 - BARS))
    BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))
    TEXT="$ICON $BAR $VOLUME%"
fi

# Show notification with 1.5 second timeout
notify-send -t 1500 "$TEXT" -h string:x-canonical-private-synchronous:volume
