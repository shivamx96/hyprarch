#!/usr/bin/env bash

read -r cpu_usage freq cores <<< "$(awk '
    /^cpu / { total=$2+$3+$4+$5+$6+$7+$8; idle=$5; usage=100*(total-idle)/total; printf "%.0f ", usage }
    /^cpu[0-9]/ { count++ }
    END { printf "0 %d", count }
' /proc/stat)"

freq_ghz=$(awk '{ sum += $1; n++ } END { printf "%.1f", sum/n/1000000 }' /proc/cpuinfo <(grep "cpu MHz" /proc/cpuinfo | awk '{print $4}') 2>/dev/null)
freq_ghz=$(grep "cpu MHz" /proc/cpuinfo | awk '{ sum += $4; n++ } END { printf "%.1f", sum/n/1000 }')

temp=""
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    raw=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp=$(awk "BEGIN {printf \"%.0f\", $raw / 1000}")
fi

tooltip="CPU: ${cpu_usage}%\\nCores: ${cores}\\nFreq: ${freq_ghz} GHz"
[ -n "$temp" ] && tooltip="${tooltip}\\nTemp: ${temp}°C"

printf '{"text":"%s","tooltip":"%s"}' "$cpu_usage" "$tooltip"
