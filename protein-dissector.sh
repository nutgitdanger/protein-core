#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
mkdir -p "$LOG_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
DISSECT_LOG="$LOG_DIR/dissector-$STAMP.log"
REPORT_FILE="$PROTEIN_HOME/03-classifier/history/dissection-report-$STAMP.txt"

echo "=== PROTEIN ACTIVE DISSECTION STARTED AT $STAMP ===" | tee -a "$DISSECT_LOG"
mkdir -p "$(dirname "$REPORT_FILE")"

{
    echo "========================================="
    echo " PROTEIN SYSTEM DISSECTION REPORT"
    echo " Timestamp: $STAMP"
    echo "========================================="

    # สำรวจไฟล์สคริปต์และโค้ดทั้งหมดเพื่อแยกแยะสถานะ
    find "$HOME" -maxdepth 3 -type f \( -name "*.sh" -o -name "*.zsh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | while read -r file; do
        # ตรวจสอบว่าไฟล์ถูกใช้งานในโปรเจกต์หลักหรืออยู่ใน config หรือไม่
        if [[ "$file" =~ '.config/dynu-audit' || "$file" =~ 'ai-router' || "$file" =~ 'network-audit' || "$file" =~ 'router-audit' ]]; then
            echo "[ACTIVE-CORE] $file -> Essential for system metabolism."
        elif [[ "$file" =~ 'backup' || "$file" =~ 'old' || "$file" =~ 'test' ]]; then
            echo "[CANDIDATE-QUARANTINE] $file -> Stale or test asset. Consider archiving."
        else
            echo "[STANDALONE] $file -> Unmapped script file."
        fi
    done

} > "$REPORT_FILE"

echo "[Dissector] Dissection report generated at: $REPORT_FILE" | tee -a "$DISSECT_LOG"
echo "=== PROTEIN ACTIVE DISSECTION COMPLETED SUCCESSFULLY ===" | tee -a "$DISSECT_LOG"
