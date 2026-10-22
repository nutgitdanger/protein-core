#!/data/data/com.termux/files/usr/bin/zsh
set -uo pipefail

WORKSPACE="$HOME/protein-core"
PROCESSING_DIR="$WORKSPACE/12-runtime/conveyor/processing"
LOG_FILE="$PROCESSING_DIR/genesis_result.log"

print "====================================================================="
print "🧬 [PROTEIN CORE - INSTANT GLANCE]"
print "====================================================================="

if [[ -f "$LOG_FILE" ]]; then
    cat "$LOG_FILE"
else
    print "STATUS=IDLE | HOMEOSTASIS=0K_READY"
fi

print "====================================================================="
print "💡 TIP: Run 'protein-super-nexus.sh scan' to refresh state."
print "====================================================================="
