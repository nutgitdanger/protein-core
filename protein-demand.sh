#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
PROJECTS_DIR="$PROTEIN_HOME/projects"
mkdir -p "$PROJECTS_DIR"

echo "============================================================="
echo " PROTEIN SYSTEM — AUTOMATED METABOLIC DEMAND & SYNC"
echo "============================================================="

for dir in "$HOME"/*(/); do
    dirname=$(basename "$dir")
    
    # ข้ามโฟลเดอร์ระบบ, โฟลเดอร์ซ่อน, และเคสพิเศษ
    [[ "$dirname" =~ '^\.' || "$dirname" == "storage" || "$dirname" == "downloads" || "$dirname" == "bin" || "$dirname" == "~" ]] && continue
    
    # ข้ามโฟลเดอร์ระบบภายใน protein และตัว projects เองเพื่อกัน Loop
    [[ "$dirname" == "protein" || "$dirname" == "dynu-audit" || "$dirname" == "protein-next" || "$dirname" == "projects" ]] && continue

    target_link="$PROJECTS_DIR/$dirname"

    if [ ! -L "$target_link" ] && [ ! -d "$target_link" ]; then
        ln -sfn "$dir" "$target_link"
        echo "  [AUTO-LINKED] Added: '$dirname' -> $PROJECTS_DIR/$dirname"
    else
        echo "  [EXISTS] Mapped: '$dirname'"
    fi
done

echo "============================================================="
echo " AUTOMATED SYNC COMPLETED SAFELY"
echo "============================================================="
