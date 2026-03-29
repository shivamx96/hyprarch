#!/usr/bin/env bash

# Unified brightness control: brightnessctl (laptop) or hyprsunset gamma (PC/external monitors)
# Usage: brightness.sh up [step] | down [step] | set <value> | get | save | restore

SAVE_FILE="/tmp/brightness-saved"
CACHE_FILE="/tmp/brightness-cache"

detect_backend() {
    if ls /sys/class/backlight/*/brightness &>/dev/null 2>&1; then
        echo "backlight"
    elif hyprctl hyprsunset gamma 2>/dev/null | grep -q .; then
        echo "gamma"
    else
        echo "none"
    fi
}

BACKEND=$(detect_backend)

get_percent() {
    case $BACKEND in
        backlight)
            local cur max
            cur=$(brightnessctl get)
            max=$(brightnessctl max)
            echo $((cur * 100 / max))
            ;;
        gamma)
            if [ -f "$CACHE_FILE" ]; then
                cat "$CACHE_FILE"
            else
                echo 100
            fi
            ;;
        *) echo 0 ;;
    esac
}

set_percent() {
    local val=$1
    (( val > 100 )) && val=100
    (( val < 5 )) && val=5
    case $BACKEND in
        backlight) brightnessctl set "${val}%" -q ;;
        gamma)
            echo "$val" > "$CACHE_FILE"
            hyprctl hyprsunset gamma "$val" &>/dev/null
            ;;
    esac
}

show_popup() {
    local percent=$1
    local bars=$((percent / 5))
    local empty=$((20 - bars))
    local bar
    bar=$(printf '█%.0s' $(seq 1 "$bars"))$(printf '░%.0s' $(seq 1 "$empty"))
    notify-send -t 1200 "󰃟 Brightness" "$bar\n$percent%" \
        -h string:x-canonical-private-synchronous:brightness
}

CMD=${1:-get}
STEP=${2:-5}

case $CMD in
    up)
        current=$(get_percent)
        new=$((current + STEP))
        (( new > 100 )) && new=100
        set_percent $new
        show_popup $new
        ;;
    down)
        current=$(get_percent)
        new=$((current - STEP))
        (( new < 5 )) && new=5
        set_percent $new
        show_popup $new
        ;;
    set)
        set_percent "$STEP"
        ;;
    get)
        get_percent
        ;;
    save)
        get_percent > "$SAVE_FILE"
        ;;
    restore)
        if [ -f "$SAVE_FILE" ]; then
            set_percent "$(cat "$SAVE_FILE")"
        fi
        ;;
esac
