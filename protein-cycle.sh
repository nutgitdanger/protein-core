#!/bin/bash
# Protein System: Full Metabolic Cycle Pipeline
CONFIG_DIR="$HOME/.config/dynu-audit"
cd "$CONFIG_DIR"

echo "====================================================="
echo "       🧬 INITIATING PROTEIN METABOLIC CYCLE"
echo "====================================================="
echo ""

# 1. ตรวจสอบสถานะภาพรวม
echo "[1/3] Running Master Status Audit..."
if [ -f "./protein-master-status.sh" ]; then
  ./protein-master-status.sh
else
  echo "  [WARN] Master status module not found."
fi

echo ""
echo "----------------------------------------------------"
echo "[2/3] Running Dry-Run Simulation..."
if [ -f "./protein-dry-run.sh" ]; then
  ./protein-dry-run.sh
else
  echo "  [WARN] Dry-run module not found."
fi

echo ""
echo "----------------------------------------------------"
echo "[3/3] Executing Autonomous Governor Check..."
if [ -f "./protein-governor.sh" ]; then
  ./protein-governor.sh
else
  echo "  [WARN] Governor module not found."
fi

echo ""
echo "====================================================="
echo "       🧬 METABOLIC CYCLE COMPLETED SUCCESSFULLY"
echo "====================================================="
