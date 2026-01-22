#!/usr/bin/env bash

# Get current brightness
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((BRIGHTNESS * 100 / MAX))

# Create visual bar
BARS=$((PERCENT / 5))
EMPTY=$((20 - BARS))
BAR=$(printf '█%.0s' $(seq 1 $BARS))$(printf '░%.0s' $(seq 1 $EMPTY))
TEXT="$BAR\n$PERCENT%"

# Show notification via dunst
notify-send -t 1200 "󰃟 Brightness" "$TEXT" -h string:x-canonical-private-synchronous:brightness
