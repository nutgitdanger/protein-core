#!/usr/bin/env zsh
PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
echo "====================================================================="
echo "           🧬 PROTEIN NETWORK & SHIELD DIAGNOSTIC                    "
echo "           Timestamp: $(date +%Y%m%d_%H%M%S)                         "
echo "====================================================================="
if [ -f "$PROTEIN_HOME/shield.state" ]; then
    cat "$PROTEIN_HOME/shield.state"
else
    echo "[🛡️ WARP SHIELD] Status: UNKNOWN (Run evolution first)"
fi
echo "---------------------------------------------------------------------"
if [ -f "$PROTEIN_HOME/base-network.state" ]; then
    cat "$PROTEIN_HOME/base-network.state"
fi
echo "---------------------------------------------------------------------"
echo "[🔗 NEURAL PATHWAYS] Active High-ROI Symlinks: $(find "$PROTEIN_HOME/projects" -type l 2>/dev/null | wc -l) paths connected"
echo "[👁️ SENSORY INDEX] Indexed Scripts: $(wc -l < "$PROTEIN_HOME/02-collector/inventory/scripts-manifest.txt" 2>/dev/null || echo 0) files mapped"
echo "====================================================================="
