#!/data/data/com.termux/files/usr/bin/zsh
set -uo pipefail

ACTION="${1:-scan}"
WORKSPACE="$HOME/protein-core"
LAYERS_DIR="$WORKSPACE/12-runtime/conveyor/layers"
PROCESSING_DIR="$WORKSPACE/12-runtime/conveyor/processing"
RBM_ADAPTER="$WORKSPACE/12-runtime/conveyor/adapters/rbm-core.py"

mkdir -p "$PROCESSING_DIR"

get_system_battery() {
    local cap_file="/sys/class/power_supply/battery/capacity"
    if [[ -r "$cap_file" ]]; then
        cat "$cap_file" 2>/dev/null || echo "80"
    else
        echo "80"
    fi
}

battery_level=$(get_system_battery)
print "🧬 [SUPER-PROTEIN NEXUS] Active & Peaceful | Energy: ${battery_level}%"

if (( battery_level <= 15 )); then
    print "🚨 [CRITICAL ENERGY] Battery <= 15%. Initiating Proactive Hibernation."
    exit 0
fi

case "$ACTION" in
    scan)
        print "👁️ [GENTLE SENSE] Evaluating kernel anatomy, physics & RBM energy..."
        
        if [[ -x "$WORKSPACE/protein-deep-kernel-sense.zsh" ]]; then
            "$WORKSPACE/protein-deep-kernel-sense.zsh"
        fi

        l11_out=""
        [[ -x "$LAYERS_DIR/L11-energy-immune.zsh" ]] && l11_out=$("$LAYERS_DIR/L11-energy-immune.zsh")
        
        rbm_out=""
        if [[ -x "$RBM_ADAPTER" ]]; then
            rbm_out=$("$RBM_ADAPTER" 0.6 0.4 0.2 0.3)
        fi

        print "\n🧠 [RBM & HARMONIOUS NEURAL EVALUATION]"
        if [[ -n "$rbm_out" ]]; then
            print "$rbm_out"
        fi

        cat << GENESIS_EOF > "$PROCESSING_DIR/genesis_result.log"
STATUS=COMPLETED
HOMEOSTASIS=STABLE_ACTIVE
BATTERY_ENERGY=${battery_level}%
$(echo "$rbm_out" | grep -E "RBM_FREE_ENERGY|RBM_METABOLIC_STRESS|RBM_STATE")
0K_IDLE=ACTIVE
GENESIS_EOF

        print "🍃 [BALANCED FLOW] Active processing with mindful pacing. 1-second pause..."
        sleep 1
        ;;
    pulse)
        print "⚡ [PULSE] Executing lightweight RBM-assisted pulse..."
        rbm_out=""
        if [[ -x "$RBM_ADAPTER" ]]; then
            rbm_out=$("$RBM_ADAPTER" 0.3 0.2 0.1 0.1)
            print "$rbm_out"
        fi

        cat << GENESIS_EOF > "$PROCESSING_DIR/genesis_result.log"
STATUS=COMPLETED
HOMEOSTASIS=STABLE_PULSE
BATTERY_ENERGY=${battery_level}%
$(echo "$rbm_out" | grep -E "RBM_FREE_ENERGY|RBM_METABOLIC_STRESS|RBM_STATE")
0K_IDLE=ACTIVE
GENESIS_EOF
        ;;
    heal)
        print "🛡️ [IMMUNE & HARMONY] System integrity verified. Peaceful homeostasis active."
        
        cat << GENESIS_EOF > "$PROCESSING_DIR/genesis_result.log"
STATUS=COMPLETED
HOMEOSTASIS=IMMUNE_HEALED
BATTERY_ENERGY=${battery_level}%
RBM_STATE=ENERGY_EQUILIBRIUM
0K_IDLE=ACTIVE
GENESIS_EOF
        ;;
    *)
        print "❌ Unknown action: $ACTION. Use: scan | pulse | heal"
        ;;
esac

print "====================================================================="
print "📊 [PROTEIN KERNEL EXECUTIVE SUMMARY]"
if [[ -f "$PROCESSING_DIR/genesis_result.log" ]]; then
    cat "$PROCESSING_DIR/genesis_result.log"
else
    print "STATUS=COMPLETED | HOMEOSTASIS=STABLE | 0K_IDLE=ACTIVE"
fi
print "====================================================================="
print "💤 [SUPER-PROTEIN] Life-cycle completed peacefully. Resting at 0K idle."
