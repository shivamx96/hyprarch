#!/usr/bin/env bash

data=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null)

if [ -z "$data" ]; then
    echo '{"text":"N/A","tooltip":"GPU not available"}'
    exit 0
fi

IFS=', ' read -r usage temp vram_used vram_total <<< "$data"

vram_used_gb=$(awk "BEGIN {printf \"%.1f\", $vram_used / 1024}")
vram_total_gb=$(awk "BEGIN {printf \"%.0f\", $vram_total / 1024}")

printf '{"text":"%s","tooltip":"GPU: %s%%\\nTemp: %s°C\\nVRAM: %s/%s GB"}' \
    "$usage" "$usage" "$temp" "$vram_used_gb" "$vram_total_gb"
