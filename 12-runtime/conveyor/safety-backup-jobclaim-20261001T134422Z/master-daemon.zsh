#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

ROOT="$HOME/.config/dynu-audit"
C="$ROOT/protein/12-runtime/conveyor"
STATE_FILE="$ROOT/protein/12-runtime/state/folding.state"

printf '🚀 [PURE SENSOR DAEMON] สแตนด์บายเฝ้าระวังไฟล์เงียบๆ...\n'
printf '💡 กด Ctrl+C เพื่อหยุด\n\n'

last_sha=""

while true; do
  if [[ -f "$STATE_FILE" ]]; then
    current_sha="$(sha256sum "$STATE_FILE" | awk '{print $1}')"
    
    # ถ้าไฟล์ขยับ ตรวจพบ SHA เปลี่ยน
    if [[ "$current_sha" != "$last_sha" ]]; then
      timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
      printf '[%s] ตรวจพบการเปลี่ยนแปลง! SHA: %.10s...\n' "$timestamp" "$current_sha"
      
      JOB_ID="folding-$current_sha"
      JOB_FILE="$C/jobs/$JOB_ID.job"
      
      # สร้าง Job ถ้ายังไม่มี
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
      fi
      
      # ส่งต่อไปให้ Evaluation Core ตัวหลักจัดการต่อตามท่อเดิมเป๊ะๆ
      "$C/units/evaluate.zsh" "$JOB_ID"
      
      printf '--------------------------------------------------\n'
      last_sha="$current_sha"
    fi
  fi
  
  sleep 4
done
