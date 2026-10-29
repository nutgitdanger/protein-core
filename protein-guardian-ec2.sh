#!/data/data/com.termux/files/usr/bin/zsh
# Termux เก็บ metric → ส่ง EC2 → รับ PAUSE/OK กลับ → สั่ง worker

WORKERS_DIR="$HOME/.cache/protein/workers"
mkdir -p "$WORKERS_DIR"

while true; do
    # 1. เก็บ metric บนเครื่อง
    ram_free=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)
    bat_json=$(termux-battery-status 2>/dev/null)
    bat=$(echo "$bat_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('percentage',80))" 2>/dev/null || echo 80)
    temp=$(echo "$bat_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('temperature',35))" 2>/dev/null || echo 35)
    plugged=$(echo "$bat_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('plugged','UNPLUGGED'))" 2>/dev/null || echo UNPLUGGED)

    # 2. ส่ง EC2 ตัดสินใจ
    decision=$(ssh -o ConnectTimeout=5 m7 \
        "python3 -c \"
ram=$ram_free; bat=$bat; temp=$temp; plugged='$plugged'
pause = ram < 600 or temp >= 42 or (bat <= 20 and plugged == 'UNPLUGGED')
ok    = ram > 900 and temp <= 38 and (bat >= 30 or plugged != 'UNPLUGGED')
import json
print('PAUSE' if pause else ('OK' if ok else 'HOLD'))
\"" 2>/dev/null || echo "HOLD")

    # 3. บันทึกสถานะ
    printf "RAM=%dMB BAT=%d%% TEMP=%sC PLUGGED=%s → %s\n" \
        "$ram_free" "$bat" "$temp" "$plugged" "$decision" \
        > "$HOME/.cache/protein/status"

    # 4. สั่ง worker
    for pid_file in "$WORKERS_DIR"/*.pid(N); do
        pid=$(cat "$pid_file" 2>/dev/null) || continue
        kill -0 "$pid" 2>/dev/null || { rm -f "$pid_file"; continue; }
        [[ "$decision" == "PAUSE" ]] && kill -STOP "$pid" 2>/dev/null
        [[ "$decision" == "OK"    ]] && kill -CONT "$pid" 2>/dev/null
    done

    sleep 30
done
