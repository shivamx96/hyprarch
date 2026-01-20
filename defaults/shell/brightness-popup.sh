#!/usr/bin/env bash

# Get current brightness
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((BRIGHTNESS * 100 / MAX))

# Create brightness bar icon
if [ "$PERCENT" -eq 0 ]; then
    ICON="󰃞"
elif [ "$PERCENT" -lt 33 ]; then
    ICON="󰃞"
elif [ "$PERCENT" -lt 66 ]; then
    ICON="󰃟"
else
    ICON="󰃠"
fi

# Create visual bar
BARS=$((PERCENT / 10))
EMPTY=$((10 - BARS))
BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))
TEXT="$ICON $BAR $PERCENT%"

# Show notification with 1.5 second timeout
notify-send -t 1500 "$TEXT" -h string:x-canonical-private-synchronous:brightness
