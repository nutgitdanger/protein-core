#!/usr/bin/env zsh
PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
TARGET_MAP="$PROTEIN_HOME/00-core/map"
mkdir -p "$TARGET_MAP"

# ล็อกเส้นทางเชื่อมโยงหลัก 4 เส้นทางให้อยู่กับที่แบบถาวร (Pinned Symlinks)
ln -sfn "$PROTEIN_HOME/11-molecules" "$TARGET_MAP/molecules"
ln -sfn "$PROTEIN_HOME/12-runtime/bridge" "$TARGET_MAP/bridge"
ln -sfn "$PROTEIN_HOME/10-governor" "$TARGET_MAP/governor"
ln -sfn "$PROTEIN_HOME/02-collector/inventory/scripts-manifest.txt" "$TARGET_MAP/manifest.txt"

echo "[PINNED] Root pathways locked and mapped successfully."
