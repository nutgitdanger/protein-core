#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
mkdir -p "$LOG_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
MET_LOG="$LOG_DIR/metabolism-$STAMP.log"

echo "=== PROTEIN METABOLIC PRUNING STARTED AT $STAMP ===" | tee -a "$MET_LOG"

# 1. ย่อยสลายและกำจัด Log เก่าหรือไฟล์ใน Quarantine ที่มีอายุเกิน 7 วัน (Metabolic Clearance)
find "$PROTEIN_HOME/08-cleaner/receipts" -type f -mtime +7 -delete 2>/dev/null || true
find "$PROTEIN_HOME/05-validator/conflicts" -type f -mtime +7 -delete 2>/dev/null || true

echo "[Metabolism] Cleaned up expired logs and stale conflict receipts." | tee -a "$MET_LOG"
echo "=== PROTEIN METABOLIC PRUNING COMPLETED SUCCESSFULLY ===" | tee -a "$MET_LOG"
