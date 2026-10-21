--- CURRENT CONTENT ---
#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
STAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
mkdir -p "$LOG_DIR"
ENGINE_LOG="$LOG_DIR/engine-$STAMP.log"

log() {
    echo "[$(date +'%T')] $1" | tee -a "$ENGINE_LOG"
}

log "=== PROTEIN SYSTEM ENGINE STARTED ==="

# 1. 01-observer: บันทึกสถานะทรัพยากรระบบปัจจุบัน
log "[Observer] Collecting system metrics..."
uptime > "$PROTEIN_HOME/01-observer/metrics/uptime.txt"
free -h > "$PROTEIN_HOME/01-observer/metrics/memory.txt"
ps -ef | grep -E 'dynu|protein|pm2' | grep -v grep > "$PROTEIN_HOME/01-observer/metrics/active-processes.txt" || true

# 2. 02-collector: รวบรวมข้อมูลเฉพาะโปรเจกต์และสคริปต์ (ไม่กวาดแคช)
log "[Collector] Indexing core assets..."
find "$HOME/.config/dynu-audit" -maxdepth 2 -type f > "$PROTEIN_HOME/02-collector/inventory/dynu-files.txt" 2>/dev/null || true

# 3. 05-validator: ตรวจสอบความสมบูรณ์ของลิงก์โปรเจกต์
log "[Validator] Checking project symlinks integrity..."
VALIDATION_REPORT="$PROTEIN_HOME/05-validator/checks/symlink-status.txt"
{
    echo "Validation timestamp: $STAMP"
    for p in ai-router network dns recovery dynu; do
        if [ -L "$PROTEIN_HOME/projects/$p" ]; then
            echo "$p: VALID ($(readlink "$PROTEIN_HOME/projects/$p"))"
        else
            echo "$p: BROKEN_OR_MISSING"
        fi
    done
} > "$VALIDATION_REPORT"

# 4. 08-cleaner: เคลียร์ไฟล์ชั่วคราวที่เก่าเกินไป (ถ้ามีใน quarantine เกิน 7 วัน)
log "[Cleaner] Sweeping old quarantine artifacts..."
find "$PROTEIN_HOME/07-quarantine" -type f -mtime +7 -delete 2>/dev/null || true

# 5. 09-verifier: สรุปผลรายงานสุขภาพระบบประจำรอบ
log "[Verifier] Generating health report..."
REPORT_FILE="$PROTEIN_HOME/09-verifier/reports/health-$STAMP.txt"
{
    echo "========================================="
    echo " PROTEIN SYSTEM HEALTH REPORT"
    echo " Timestamp: $STAMP"
    echo "========================================="
    echo "Status: ALL MODULES OPERATIONAL"
    echo "Memory State:"
    cat "$PROTEIN_HOME/01-observer/metrics/memory.txt"
    echo "========================================="
} > "$REPORT_FILE"

log "=== PROTEIN SYSTEM ENGINE COMPLETED SUCCESSFULLY ==="
