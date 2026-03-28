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

# Intel GPU
if command -v intel_gpu_top &>/dev/null; then
    data=$(intel_gpu_top -J -s 500 -o - 2>/dev/null | head -c 4096)
    if [ -n "$data" ]; then
        # Parse the first JSON period entry
        usage=$(echo "$data" | python3 -c "
import sys, json
raw = sys.stdin.read()
# intel_gpu_top outputs JSON array periods; grab first complete one
start = raw.find('{', raw.find('\"period\"'))
end = raw.find('}', raw.rfind('\"rc6\"')) + 1
if start >= 0 and end > start:
    obj = json.loads(raw[start:end])
    engines = obj.get('engines', {})
    # Sum all engine busy percentages, use max as overall usage
    busy = max((e.get('busy', 0) for e in engines.values()), default=0)
    freq_req = obj.get('frequency', {}).get('requested', 0)
    freq_act = obj.get('frequency', {}).get('actual', 0)
    rc6 = obj.get('rc6', {}).get('value', 0)
    print(f'{busy:.0f}|{freq_act:.0f}|{rc6:.0f}')
else:
    print('0|0|0')
" 2>/dev/null)
        IFS='|' read -r busy freq rc6 <<< "$usage"
        printf '{"text":"%s","tooltip":"GPU: %s%%\\nFreq: %s MHz\\nRC6 (idle): %s%%"}' \
            "$busy" "$busy" "$freq" "$rc6"
        exit 0
    fi
fi

echo '{"text":"N/A","tooltip":"GPU not available"}'
