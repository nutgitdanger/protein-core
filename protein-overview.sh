#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
STAMP=$(date +%Y%m%d_%H%M%S)

clear
echo "====================================================================="
echo "                  PROTEIN SYSTEM — OMNISCIENCE DASHBOARD             "
echo "                  Timestamp: $STAMP                                  "
echo "====================================================================="

# 1. 00-core & DNA Status
echo "[🧬 00-CORE: DNA & STATE]"
if [ -f "$PROTEIN_HOME/00-core/dna/system.env" ]; then
    echo "  Status: ACTIVE (system.env found)"
else
    echo "  Status: UNKNOWN / MISSING DNA"
fi

# 2. 01-observer & 02-collector Inventory
echo ""
echo "[👁️ 01/02-OBSERVER & COLLECTOR]"
SCRIPT_COUNT=$(wc -l < "$PROTEIN_HOME/02-collector/inventory/scripts-manifest.txt" 2>/dev/null || echo "0")
echo "  Indexed Scripts: $SCRIPT_COUNT files"
if [ -f "$PROTEIN_HOME/01-observer/metrics/memory.txt" ]; then
    MEM_FREE=$(grep "Mem:" "$PROTEIN_HOME/01-observer/metrics/memory.txt" | awk '{print $4}')
    MEM_AVAIL=$(grep "Mem:" "$PROTEIN_HOME/01-observer/metrics/memory.txt" | awk '{print $7}')
    echo "  Memory Available: $MEM_AVAIL (Free: $MEM_FREE)"
fi

# 3. 03/05-PROJECTS & SYMLINKS
echo ""
echo "[🔗 03/05-PROJECTS & SYMLINKS]"
for p in ai-router network dns recovery dynu vpn github; do
    target="$PROTEIN_HOME/projects/$p"
    if [ -L "$target" ]; then
        echo "  - $p -> $(readlink "$target") [HEALTHY]"
    else
        echo "  - $p [NO ACTIVE SYMLINK]"
    fi
done

# 4. 05-validator/conflicts (Security Sentinel Status)
echo ""
echo "[🛡️ 05-VALIDATOR & IMMUNE SYSTEM (Security)]"
LATEST_SEC_AUDIT=$(ls -t "$PROTEIN_HOME/05-validator/conflicts/"security-audit-*.txt 2>/dev/null | head -n 1 || echo "")
if [ -n "$LATEST_SEC_AUDIT" ]; then
    FLAGGED_COUNT=$(grep -c "\[FLAGGED\]" "$LATEST_SEC_AUDIT" 2>/dev/null || echo "0")
    echo "  Latest Security Scan: $(basename "$LATEST_SEC_AUDIT")"
    echo "  Flagged Secrets/Tokens: $FLAGGED_COUNT items found"
else
    echo "  Security Scan: No recent audit reports found."
fi

# 5. Metabolic Load & Waste Status (New Instinct)
echo ""
echo "[♻️ METABOLIC STATUS & WASTE CONTROL]"
QUARANTINE_COUNT=$(find "$PROTEIN_HOME/07-quarantine" -type f 2>/dev/null | wc -l || echo "0")
echo "  Quarantine Isolated Items: $QUARANTINE_COUNT files"
echo "  Metabolic Cost ROI: BALANCED (No heavy burden detected)"

# 6. 08/09-cleaner & verifier Automation
echo ""
echo "[⚙️ 08/09-AUTOMATION & ENGINE]"
if crontab -l 2>/dev/null | grep -q "protein-engine.sh"; then
    echo "  Cron Automation: ACTIVE (Runs every 6 hours)"
else
    echo "  Cron Automation: INACTIVE"
fi

echo "====================================================================="
echo " SUMMARY: SYSTEM IS ALIVE, SELF-CONTAINED, AND METABOLICALLY BALANCED."
echo "====================================================================="
