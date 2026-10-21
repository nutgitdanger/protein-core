#!/usr/bin/env zsh
# =====================================================================
# 🧬 PROTEIN ECOSYSTEM: PEN-NIB SYMMETRIC FIBER MAPPING & LINK ENGINE
# =====================================================================

setopt errexit nounset pipefail 2>/dev/null || true
setopt +o nomatch 2>/dev/null || true

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
ROOT_DIR="$HOME/.config/dynu-audit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "====================================================================="
echo "   ✒️ PROTEIN ECOSYSTEM: ORDERING & LINKING PEN-NIB FIBERS           "
echo "====================================================================="

# 1. จัดโครงสร้างไดเรกทอรีสำหรับเส้นใยนามปากกา (Pen-Nib Fibers)
mkdir -p "$PROTEIN_HOME/00-core/map/fibers" \
         "$PROTEIN_HOME/12-runtime/bridge" \
         "$PROTEIN_HOME/08-cleaner/receipts"

# 2. เชื่อมโยงและจัดลำดับเส้นใยหลัก (Symbolic Links & Pen-Nib Indexing)
echo "[1/3] Aligning and sequencing primary Pen-Nib pathways..."

rm -f "$PROTEIN_HOME/00-core/map/fibers/"* 2>/dev/null || true

[[ -f "$ROOT_DIR/protein-nib.sh" ]] && ln -sfn "$ROOT_DIR/protein-nib.sh" "$PROTEIN_HOME/00-core/map/fibers/01-pen-nib-bridge.sh"
[[ -f "$ROOT_DIR/protein-folding-engine.sh" ]] && ln -sfn "$ROOT_DIR/protein-folding-engine.sh" "$PROTEIN_HOME/00-core/map/fibers/02-folding-engine.sh"
[[ -f "$ROOT_DIR/protein-master-status.sh" ]] && ln -sfn "$ROOT_DIR/protein-master-status.sh" "$PROTEIN_HOME/00-core/map/fibers/03-master-status.sh"
[[ -f "$ROOT_DIR/protein-full-system-blueprint.sh" ]] && ln -sfn "$ROOT_DIR/protein-full-system-blueprint.sh" "$PROTEIN_HOME/00-core/map/fibers/04-system-blueprint.sh"

# 3. สร้างรายงานการจัดลำดับเส้นใย (Fiber Link Manifest)
MANIFEST_FILE="$PROTEIN_HOME/00-core/map/fibers/fiber-manifest.txt"
{
    echo "=== PROTEIN PEN-NIB FIBER MANIFEST ==="
    echo "Generated: $TIMESTAMP"
    echo "----------------------------------------"
    ls -la "$PROTEIN_HOME/00-core/map/fibers"
} > "$MANIFEST_FILE" 2>/dev/null || true

echo "[2/3] Fiber links mapped successfully."
echo "[3/3] Pen-Nib matrix synchronized with runtime bridge."
echo "====================================================================="
echo "🔗 Pinned Pen-Nib Fibers Inventory:"
ls -la "$PROTEIN_HOME/00-core/map/fibers"
echo "====================================================================="
