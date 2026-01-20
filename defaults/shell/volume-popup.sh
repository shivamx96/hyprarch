#!/usr/bin/env bash

# Get current volume
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "yes" || echo "no")

# Create volume bar
if [ "$MUTED" = "yes" ]; then
    ICON="󰖁"
    TEXT="Volume"
    DISPLAY="Muted"
else
    if [ "$VOLUME" -lt 33 ]; then
        ICON="󰕿"
    elif [ "$VOLUME" -lt 66 ]; then
        ICON="󰖀"
    else
        ICON="󰕾"
    fi

    # Create visual bar (20 chars max for good fit)
    BARS=$((VOLUME / 5))
    EMPTY=$((20 - BARS))
    BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))
    DISPLAY="$BAR\n$VOLUME%"
fi

# Show notification with 1.2 second timeout
notify-send -t 1200 "$ICON Volume" "$DISPLAY" -h string:x-canonical-private-synchronous:volume
