#!/usr/bin/env bash

# Wallpaper manager for swww

WALLPAPER_DIR="$HOME/.local/share/hyprarch/wallpapers"
CURRENT_WALLPAPER="$HOME/.cache/hyprarch-wallpaper"

# Create wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Function to set wallpaper
set_wallpaper() {
    local wallpaper="$1"

    if [ ! -f "$wallpaper" ]; then
        echo "Wallpaper not found: $wallpaper"
        return 1
    fi

    # Initialize swww if not already running
    if ! pgrep -x "swww-daemon" > /dev/null; then
        swww init
        sleep 1
    fi

    # Set wallpaper with transition
    swww img "$wallpaper" --transition-type wipe --transition-duration 1

    # Save current wallpaper
    echo "$wallpaper" > "$CURRENT_WALLPAPER"
}

# Function to get random wallpaper
random_wallpaper() {
    shopt -s nullglob
    local wallpapers=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,JPG,JPEG,PNG})
    shopt -u nullglob

    if [ ${#wallpapers[@]} -eq 0 ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        return 1
    fi

    local random_idx=$((RANDOM % ${#wallpapers[@]}))
    echo "${wallpapers[$random_idx]}"
}

# Function to cycle wallpapers
cycle_wallpaper() {
    shopt -s nullglob
    local wallpapers=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,JPG,JPEG,PNG})
    shopt -u nullglob

    if [ ${#wallpapers[@]} -eq 0 ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        return 1
    fi

    local current="$(cat "$CURRENT_WALLPAPER" 2>/dev/null)"
    local next_idx=0

    for i in "${!wallpapers[@]}"; do
        if [ "${wallpapers[$i]}" = "$current" ]; then
            next_idx=$(( (i + 1) % ${#wallpapers[@]} ))
            break
        fi
    done

    set_wallpaper "${wallpapers[$next_idx]}"
}

# Main logic
case "${1:-random}" in
    set)
        set_wallpaper "$2"
        ;;
    random)
        local wp=$(random_wallpaper)
        set_wallpaper "$wp"
        ;;
    cycle)
        cycle_wallpaper
        ;;
    *)
        echo "Usage: $0 {set <path>|random|cycle}"
        exit 1
        ;;
esac
