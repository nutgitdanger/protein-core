#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
mkdir -p "$LOG_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
SENTINEL_LOG="$LOG_DIR/sentinel-$STAMP.log"
REPORT_FILE="$PROTEIN_HOME/05-validator/conflicts/security-audit-$STAMP.txt"

echo "=== PROTEIN SECURITY SENTINEL STARTED AT $STAMP ===" | tee -a "$SENTINEL_LOG"

mkdir -p "$(dirname "$REPORT_FILE")"

# ค้นหาแบบจำกัดประเภทไฟล์และตัดโฟลเดอร์ขยะออกเด็ดขาด เพื่อป้องกันการค้าง
{
    echo "========================================="
    echo " SECURITY SENTINEL AUDIT REPORT"
    echo " Timestamp: $STAMP"
    echo "========================================="
    
    find "$HOME/.config/dynu-audit" "$HOME/ai-router" "$HOME/network-audit" \
        -type f \( -name "*.env" -o -name "*.sh" -o -name "*.zsh" -o -name "*.conf" -o -name "*.json" \) \
        2>/dev/null | while read -r file; do
            if grep -qEi 'password\s*=|secret\s*=|api_key\s*=|token\s*=' "$file" 2>/dev/null; then
                echo "[FLAGGED] Potential secret found in: $file"
            fi
        done
        
    echo "Scan completed successfully."
} > "$REPORT_FILE"

echo "[Sentinel] Security audit report generated at: $REPORT_FILE" | tee -a "$SENTINEL_LOG"
echo "=== PROTEIN SECURITY SENTINEL COMPLETED SUCCESSFULLY ===" | tee -a "$SENTINEL_LOG"
