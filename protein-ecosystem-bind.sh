#!/usr/bin/env zsh
PROTEIN_HOME="$HOME/.config/dynu-audit"
TARGET_MAP="$PROTEIN_HOME/protein/00-core/map"
mkdir -p "$TARGET_MAP"

ln -sfn "$PROTEIN_HOME/protein/11-molecules" "$TARGET_MAP/molecules"
ln -sfn "$PROTEIN_HOME/protein/12-runtime/bridge" "$TARGET_MAP/bridge"
ln -sfn "$PROTEIN_HOME/protein/10-governor" "$TARGET_MAP/governor"
ln -sfn "$PROTEIN_HOME/protein/02-collector/inventory/scripts-manifest.txt" "$TARGET_MAP/manifest.txt"
ln -sfn "$PROTEIN_HOME/protein-system-info.sh" "$TARGET_MAP/sys-info"
ln -sfn "$PROTEIN_HOME/protein-full-audit.sh" "$TARGET_MAP/full-audit"
ln -sfn "$PROTEIN_HOME/protein-network-monitor.sh" "$TARGET_MAP/net-monitor"

echo "====================================================================="
echo "   🧬 PROTEIN ECOSYSTEM: ALL SYSTEM PATHWAYS & SCRIPTS LINKED       "
echo "====================================================================="
ls -l "$TARGET_MAP"
echo "====================================================================="
