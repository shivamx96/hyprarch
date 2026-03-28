#!/usr/bin/env bash

# NVIDIA GPU
if command -v nvidia-smi &>/dev/null; then
    data=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null)
    if [ -n "$data" ]; then
        IFS=', ' read -r usage temp vram_used vram_total <<< "$data"
        vram_used_gb=$(awk "BEGIN {printf \"%.1f\", $vram_used / 1024}")
        vram_total_gb=$(awk "BEGIN {printf \"%.0f\", $vram_total / 1024}")
        printf '{"text":"%s","tooltip":"GPU: %s%%\\nTemp: %s°C\\nVRAM: %s/%s GB"}' \
            "$usage" "$usage" "$temp" "$vram_used_gb" "$vram_total_gb"
        exit 0
    fi
fi

# Intel GPU — read frequency from sysfs (no root needed)
for card in /sys/class/drm/card*/; do
    gt_dir="$card/gt/gt0"
    [ -d "$gt_dir" ] || gt_dir="$card"

    freq_file="$gt_dir/rps_cur_freq_mhz"
    max_file="$gt_dir/rps_max_freq_mhz"

    if [ -r "$freq_file" ] && [ -r "$max_file" ]; then
        freq=$(cat "$freq_file")
        max_freq=$(cat "$max_file")
        usage=$(awk "BEGIN {v=100*$freq/$max_freq; printf \"%.0f\", (v>100?100:v)}")

        tooltip="GPU: ${usage}%\\nFreq: ${freq}/${max_freq} MHz"

        # Try reading RC6 (idle residency)
        rc6_file="$gt_dir/rc6_residency_ms"
        [ -r "$rc6_file" ] && tooltip="${tooltip}\\nRC6: $(cat "$rc6_file") ms"

        printf '{"text":"%s","tooltip":"%s"}' "$usage" "$tooltip"
        exit 0
    fi
done

echo '{"text":"N/A","tooltip":"GPU not available"}'
