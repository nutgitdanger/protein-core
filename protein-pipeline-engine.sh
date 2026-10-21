#!/usr/bin/env zsh
set -uo pipefail

WORKSPACE="$HOME/protein-core/pipeline"
PENDING="$WORKSPACE/pending"
PROCESSING="$WORKSPACE/processing"
COMPLETED="$WORKSPACE/completed"
FAILED="$WORKSPACE/failed"

mkdir -p "$PENDING" "$PROCESSING" "$COMPLETED" "$FAILED"

for stuck in "$PROCESSING"/*(N); do
    [[ -e "$stuck" ]] && mv "$stuck" "$PENDING/" && print "♻️ [RECOVERED] Stale task returned."
done

for job in "$PENDING"/*.json(N); do
    [[ -e "$job" ]] || continue
    
    local name=$(basename "$job")
    local proc="$PROCESSING/$name"
    
    mv "$job" "$proc" || continue
    
    local exec=$(grep -o '"executor"[[:space:]]*:[[:space:]]*"[^"]*"' "$proc" | cut -d'"' -f4)
    
    if [[ -n "$exec" && "$exec" != "None" && -x "$HOME/protein-core/$exec" ]]; then
        cd "$HOME/protein-core" && ./"$exec"
        if [[ $? -eq 0 ]]; then
            mv "$proc" "$COMPLETED/" && print "✅ [DONE] $name"
        else
            mv "$proc" "$FAILED/" && print "❌ [FAIL] $name"
        fi
    else
        sleep 0.02
        mv "$proc" "$COMPLETED/" && print "✅ [VIRTUAL] $name"
    fi
done
print "💤 [PIPELINE] Queue clear. Returning to 0K idle state."
