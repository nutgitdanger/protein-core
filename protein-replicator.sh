#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
LOG_DIR="$PROTEIN_HOME/08-cleaner/receipts"
mkdir -p "$LOG_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
REP_LOG="$LOG_DIR/replicator-$STAMP.log"

echo "=== PROTEIN REPLICATOR & EXPANSION STARTED AT $STAMP ===" | tee -a "$REP_LOG"

# 1. ระบบคัดเลือกและขยายพันธุ์ (Selective Replication)
# ตรวจสอบโฟลเดอร์โปรเจกต์สำคัญที่ยังไม่ได้เชื่อมโยง และดึงเข้ามาไว้ในสารบบ Projects
for dir in "$HOME"/*(/); do
    dirname=$(basename "$dir")
    
    # กฎการคัดเลือก: ข้ามโฟลเดอร์ระบบ โฟลเดอร์ซ่อน หรือโฟลเดอร์ที่ไม่ใช่โปรเจกต์
    [[ "$dirname" =~ '^\.' || "$dirname" == "storage" || "$dirname" == "downloads" || "$dirname" == "bin" || "$dirname" == "logs" || "$dirname" == "archives" || "$dirname" == "evidence" || "$dirname" == "reports" ]] && continue
    
    target_link="$PROTEIN_HOME/projects/$dirname"
    
    # หากพบว่ามีโปรเจกต์จริงแต่ยังไม่มี Symlink ให้ระบบทำการ "จำลองและขยายขอบเขต" เข้ามาเชื่อมโยงทันที
    if [ ! -L "$target_link" ] && [ ! -d "$target_link" ]; then
        if [ -f "$dir/package.json" ] || [ -f "$dir/Cargo.toml" ] || [ -f "$dir/requirements.txt" ] || [ -n "$(find "$dir" -maxdepth 2 -name '*.sh' -o -name '*.zsh' 2>/dev/null)" ]; then
            ln -sfn "$dir" "$target_link"
            echo "[Replicator] EXPANDED: Automatically mapped new project asset -> $dirname" | tee -a "$REP_LOG"
        fi
    fi
done

echo "=== PROTEIN REPLICATOR COMPLETED SUCCESSFULLY ===" | tee -a "$REP_LOG"
