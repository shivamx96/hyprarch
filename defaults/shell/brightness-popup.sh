#!/usr/bin/env bash

# Get current brightness
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((BRIGHTNESS * 100 / MAX))

# Create brightness bar icon
if [ "$PERCENT" -lt 33 ]; then
    ICON="󰃞"
elif [ "$PERCENT" -lt 66 ]; then
    ICON="󰃟"
else
    ICON="󰃠"
fi

# Create visual bar (20 chars max for good fit)
BARS=$((PERCENT / 5))
EMPTY=$((20 - BARS))
BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))
DISPLAY="$BAR\n$PERCENT%"

# Show notification with 1.2 second timeout
notify-send -t 1200 "$ICON Brightness" "$DISPLAY" -h string:x-canonical-private-synchronous:brightness
