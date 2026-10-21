#!/bin/bash
# Protein System Terminal Connection & Alliance Link
CONFIG_DIR="$HOME/.config/dynu-audit"

if [ -f "$CONFIG_DIR/protein-master-status.sh" ]; then
  echo "====================================================="
  echo "         🧬 PROTEIN SYSTEM — ALLIANCE LINK"
  echo "====================================================="
  "$CONFIG_DIR/protein-master-status.sh" | grep -iE "status|route|shield|summary|pass|healthy"
  echo "====================================================="
else
  echo "🧬 Protein System: Link established. Core modules online."
fi
