#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
QUARANTINE_DIR="$PROTEIN_HOME/07-quarantine/$(date +%Y%m%d)"
mkdir -p "$LOG_DIR" "$QUARANTINE_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
COST_LOG="$LOG_DIR/metabolic-cost-$STAMP.log"

echo "=== PROTEIN METABOLIC COST & ROI EVALUATOR STARTED AT $STAMP ===" | tee -a "$COST_LOG"

# หลักการโปรตีน: ไฟล์หรือบันทึกเก่าที่อายุเกิน 7 วัน ประโยชน์หมดอายุแต่ยังแบกน้ำหนักไว้ จะถูกตีค่าเป็น "ภาระส่วนเกิน" (Waste)
find "$PROTEIN_HOME/08-cleaner/receipts" "$PROTEIN_HOME/05-validator/conflicts" "$PROTEIN_HOME/01-observer/metrics" -type f -mtime +7 2>/dev/null | while read -r oldfile; do
    fsize=$(du -k "$oldfile" | cut -f1 2>/dev/null || echo "0")
    echo "[METABOLIC BURDEN] Low utility asset found: $oldfile (Weight: ${fsize}KB)" | tee -a "$COST_LOG"
    
    # ส่งเข้าห้องกักกันเพื่อลดน้ำหนักระบบโดยอัตโนมัติ
    mv "$oldfile" "$QUARANTINE_DIR/"
    echo "  -> [PRUNED & ISOLATED] Relocated to quarantine to lighten metabolic load." | tee -a "$COST_LOG"
done

echo "=== METABOLIC COST EVALUATION COMPLETED SUCCESSFULLY ===" | tee -a "$COST_LOG"
