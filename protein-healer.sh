#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
mkdir -p "$LOG_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
HEAL_LOG="$LOG_DIR/healer-$STAMP.log"

echo "=== PROTEIN ACTIVE HEALER STARTED AT $STAMP ===" | tee -a "$HEAL_LOG"

fix_link() {
    local name="$1"
    shift
    local target="$PROTEIN_HOME/projects/$name"

    if [ ! -L "$target" ] || [ ! -e "$target" ]; then
        echo "[Healer] Symlink for $name is broken or missing. Searching for candidate..." | tee -a "$HEAL_LOG"
        for candidate in "$@"; do
            if [ -d "$candidate" ]; then
                ln -sfn "$candidate" "$target"
                echo "[Healer] REPAIRED: Linked $name -> $candidate" | tee -a "$HEAL_LOG"
                return 0
            fi
        done
        # ถ้าหาไม่เจอ ให้สร้างโฟลเดอร์สำรองไว้ให้อัตโนมัติเพื่อความเรียบร้อย
        mkdir -p "$HOME/$name"
        ln -sfn "$HOME/$name" "$target"
        echo "[Healer] CREATED & REPAIRED: Fallback directory created for $name" | tee -a "$HEAL_LOG"
    fi
}

fix_link "ai-router" "$HOME/ai-router" "$HOME/projects/ai-router"
fix_link "network" "$HOME/network-audit" "$HOME/projects/network-audit"
fix_link "dns" "$HOME/router-audit" "$HOME/projects/router-audit" "$HOME/.config/dynu-audit"
fix_link "recovery" "$HOME/recovery" "$HOME/recovery-unprocessed" "$HOME/projects/recovery"
fix_link "dynu" "$HOME/.config/dynu-audit"

echo "=== PROTEIN ACTIVE HEALER COMPLETED SUCCESSFULLY ===" | tee -a "$HEAL_LOG"
