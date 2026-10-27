#!/data/data/com.termux/files/usr/bin/zsh
WORKSPACE="$HOME/protein-core"
LOG="$WORKSPACE/12-runtime/conveyor/processing/genesis_result.log"
print "====================================================================="
print "🧬 [PROTEIN CORE - INSTANT GLANCE]"
print "====================================================================="
if [[ -f "$LOG" ]]; then
    cat "$LOG"
else
    print "STATUS=IDLE | HOMEOSTASIS=0K_READY"
fi
print "====================================================================="
print "💡 TIP: Run pscan to refresh."
print "====================================================================="
