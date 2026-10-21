#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

ROOT="$HOME/.config/dynu-audit"
C="$ROOT/protein/12-runtime/conveyor"
STATE_FILE="$ROOT/protein/12-runtime/state/folding.state"

printf '=== SENSOR GATE DAEMON STARTED ===\n'
printf 'MONITORING: %s\n' "$STATE_FILE"
printf 'PRESS CTRL+C TO STOP.\n\n'

last_sha=""

while true; do
  if [[ -f "$STATE_FILE" ]]; then
    current_sha="$(sha256sum "$STATE_FILE" | awk '{print $1}')"
    
    # ถ้า SHA เปลี่ยน (ตรวจพบการเปลี่ยนแปลง / Change Detection)
    if [[ "$current_sha" != "$last_sha" ]]; then
      timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
      printf '[%s] DETECTED CHANGE! NEW SHA: %s\n' "$timestamp" "$current_sha"
      
      JOB_ID="folding-$current_sha"
      JOB_FILE="$C/jobs/$JOB_ID.job"
      
      # สร้าง Job อัตโนมัติถ้ายังไม่มี
      if [[ ! -f "$JOB_FILE" ]]; then
        cat > "$JOB_FILE" <<JOB_EOF
JOB_ID=$JOB_ID
INPUT_SHA256=$current_sha
METHOD=folding
PARAMS=default
DEPENDENCY=none
GENERATION=1
CREATED=$timestamp
STATUS=READY
INPUT_REF=$STATE_FILE
JOB_EOF
        printf '[%s] CREATED JOB: %s\n' "$timestamp" "$JOB_ID"
      fi
      
      # ส่งเข้า Evaluation Engine ทันที
      "$C/units/evaluate.zsh" "$JOB_ID"
      printf '--------------------------------------------------\n'
      
      last_sha="$current_sha"
    fi
  fi
  
  # หน่วงเวลา 3 วินาทีต่อรอบการตรวจจับ (ประหยัด CPU / แบตเตอรี่บนมือถือ)
  sleep 3
done
