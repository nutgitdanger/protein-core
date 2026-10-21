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
      
        "$C/units/job-create.zsh" "$JOB_FILE" "$current_sha" "folding" "canonical" "none" "1" "$timestamp" "$STATE_FILE"
        CREATE_RC=$?
        if [[ "$CREATE_RC" -eq 0 ]]; then
          printf '[%s] CREATED JOB: %s\n' "$timestamp" "$JOB_ID"
        elif [[ "$CREATE_RC" -ne 4 ]]; then
          printf '[%s] JOB CREATE FAILED RC=%s JOB_ID=%s\n' "$timestamp" "$CREATE_RC" "$JOB_ID"
          sleep 1
          continue
        fi
      
      # ส่งเข้า Evaluation Engine ทันที
      "$C/units/evaluate.zsh" "$JOB_ID"
      printf '--------------------------------------------------\n'
      
      last_sha="$current_sha"
    fi
  fi
  
  # หน่วงเวลา 3 วินาทีต่อรอบการตรวจจับ (ประหยัด CPU / แบตเตอรี่บนมือถือ)
    sleep 3600
done
