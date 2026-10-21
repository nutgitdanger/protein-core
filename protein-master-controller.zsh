#!/usr/bin/env zsh
set -uo pipefail

WORKSPACE="$HOME/protein-core/pipeline"
PENDING="$WORKSPACE/pending"
PROCESSING="$WORKSPACE/processing"
COMPLETED="$WORKSPACE/completed"
FAILED="$WORKSPACE/failed"

mkdir -p "$PENDING" "$PROCESSING" "$COMPLETED" "$FAILED"

print "🧠 [MASTER CONTROLLER] Initializing Protein Hierarchy & Multi-Worker Brain..."

for job in "$PENDING"/*.json(N); do
    [[ -e "$job" ]] || continue
    
    local name=$(basename "$job")
    local proc="$PROCESSING/$name"
    
    mv "$job" "$proc" || continue
    
    print "🧬 [DISPATCHER] Master Controller acquired: $name"
    
    local task_type=$(grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' "$proc" | cut -d'"' -f4)
    local target_branch=$(grep -o '"branch"[[:space:]]*:[[:space:]]*"[^"]*"' "$proc" | cut -d'"' -f4)
    
    print "  ├── Classified Type   : ${task_type:-General}"
    print "  └── Assigned Branch   : ${target_branch:-Root-Core}"
    
    case "${target_branch:-root}" in
        "network"|"audit")
            print "  ⚡ [ROUTER] Routing to Low-Power Cortex-A53 Efficiency Stream..."
            sleep 0.03
            ;;
        "folding"|"computation")
            print "  🚀 [ROUTER] Activating High-Performance Cortex-A73 Parallel Workers..."
            sleep 0.05
            ;;
        *)
            print "  ⚙️ [ROUTER] Processing via Standard Protein Pathway..."
            sleep 0.02
            ;;
    esac
    
    local exec=$(grep -o '"executor"[[:space:]]*:[[:space:]]*"[^"]*"' "$proc" | cut -d'"' -f4)
    if [[ -n "$exec" && "$exec" != "None" && -x "$HOME/protein-core/$exec" ]]; then
        cd "$HOME/protein-core" && ./"$exec"
        if [[ $? -eq 0 ]]; then
            mv "$proc" "$COMPLETED/" && print "✅ [MASTER SUCCESS] $name -> Vaulted"
        else
            mv "$proc" "$FAILED/" && print "❌ [MASTER FAILED] $name -> Quarantined"
        fi
    else
        mv "$proc" "$COMPLETED/" && print "✅ [MASTER VIRTUAL DONE] $name -> Vaulted"
    fi
    
    print "💤 [MASTER] Task branch settled. Returning to 0K idle state."
done
