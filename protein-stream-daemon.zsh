#!/usr/bin/env zsh
set -uo pipefail

WORKSPACE="$HOME/protein-core/pipeline"
PENDING="$WORKSPACE/pending"
PROCESSING="$WORKSPACE/processing"
COMPLETED="$WORKSPACE/completed"
FAILED="$WORKSPACE/failed"

mkdir -p "$PENDING" "$PROCESSING" "$COMPLETED" "$FAILED"

print "👁️ [STREAM] Protein Real-Time Daemon active. Listening to pipeline stream..."

# ใช้ inotifywait เฝ้าระวังโฟลเดอร์ pending แบบเรียลไทม์ (กินทรัพยากรเป็น 0 ตอนไม่มีอีเวนต์)
inotifywait -m -e MOVED_TO -e CLOSE_WRITE --format '%f' "$PENDING" | while read filename; do
    [[ -z "$filename" ]] && continue
    
    job="$PENDING/$filename"
    [[ -f "$job" ]] || continue
    
    proc="$PROCESSING/$filename"
    mv "$job" "$proc" || continue
    
    print "⚡ [STREAM EVENT] Real-time task detected: $filename -> Routing to 8-Core Engine"
    
    # ดึงค่า executor และประมวลผลทันที
    local exec=$(grep -o '"executor"[[:space:]]*:[[:space:]]*"[^"]*"' "$proc" | cut -d'"' -f4)
    
    if [[ -n "$exec" && "$exec" != "None" && -x "$HOME/protein-core/$exec" ]]; then
        cd "$HOME/protein-core" && ./"$exec"
        if [[ $? -eq 0 ]]; then
            mv "$proc" "$COMPLETED/" && print "✅ [STREAM DONE] $filename"
        else
            mv "$proc" "$FAILED/" && print "❌ [STREAM FAIL] $filename"
        fi
    else
        sleep 0.02
        mv "$proc" "$COMPLETED/" && print "✅ [STREAM VIRTUAL] $filename"
    fi
    
    print "💤 [STREAM] Returning to 0K idle state."
done
