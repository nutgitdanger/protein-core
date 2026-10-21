#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
mkdir -p "$LOG_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/classification-$STAMP.log"

echo "=== PROTEIN CLASSIFIER STARTED AT $STAMP ===" | tee -a "$LOG_FILE"

# 1. รวบรวมข้อมูล DNA พื้นฐานเข้า 00-core
if [ -f "$PROTEIN_HOME/data/snapshots/20260904_015530/system.env" ]; then
    cp "$PROTEIN_HOME/data/snapshots/20260904_015530/system.env" "$PROTEIN_HOME/00-core/dna/"
fi

# 2. ทำ Inventory ไฟล์สคริปต์และโปรเจกต์เข้า 02-collector
find "$HOME" -maxdepth 2 -type f \( -name "*.sh" -o -name "*.zsh" \) > "$PROTEIN_HOME/02-collector/inventory/scripts-manifest.txt" 2>/dev/null || true
find "$HOME" -maxdepth 2 -type d > "$PROTEIN_HOME/02-collector/inventory/directories-manifest.txt" 2>/dev/null || true

# 3. ฟังก์ชันช่วยผูกลิงก์โปรเจกต์จากตำแหน่งจริง
link_project() {
    local name="$1"
    shift
    for candidate in "$@"; do
        if [ -d "$candidate" ]; then
            ln -sfn "$candidate" "$PROTEIN_HOME/projects/$name"
            echo "Linked $name -> $candidate" | tee -a "$LOG_FILE"
            return 0
        fi
    done
}

link_project "ai-router" "$HOME/ai-router" "$HOME/projects/ai-router"
link_project "network" "$HOME/network-audit" "$HOME/projects/network-audit"
link_project "dns" "$HOME/router-audit" "$HOME/projects/router-audit" "$HOME/.config/dynu-audit"
link_project "recovery" "$HOME/recovery-project" "$HOME/projects/recovery"
link_project "dynu" "$HOME/.config/dynu-audit"
link_project "github" "$HOME/projects/github"

echo "=== CLASSIFICATION COMPLETED SUCCESSFULLY ===" | tee -a "$LOG_FILE"
