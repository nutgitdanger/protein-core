#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$HOME/.config/dynu-audit"
PROTEIN_DIR="$ROOT_DIR/protein"

echo "=================================================="
echo " [1/3] Path & Environment Validation"
echo "=================================================="
[ -d "$ROOT_DIR" ] && echo "[OK] Root: $ROOT_DIR" || { echo "[ERROR] Root missing"; exit 1; }
[ -d "$PROTEIN_DIR" ] && echo "[OK] Protein dir ready" || mkdir -p "$PROTEIN_DIR"

echo "=================================================="
echo " [2/3] System Status Overview"
echo "=================================================="
du -sh "$ROOT_DIR" 2>/dev/null || true
ls -lh "$HOME" | grep -E "dynu-audit|protein-machine-map" || echo "No archives found."

echo "=================================================="
echo " [3/3] Ready for Operations"
echo "=================================================="
echo "Run: bash ~/.config/dynu-audit/protein-smart-manager.sh"
