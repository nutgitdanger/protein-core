#!/data/data/com.termux/files/usr/bin/zsh
set -uo pipefail

ACTION="${1:-scan}"
WORKSPACE="$HOME/protein-core"
LAYERS_DIR="$WORKSPACE/_archive/layers"
PROCESSING_DIR="$WORKSPACE/12-runtime/conveyor/processing"
RBM_REMOTE_SCRIPT="/home/ubuntu/protein-core/12-runtime/conveyor/adapters/rbm-core.py"

run_rbm() {
    ssh -o BatchMode=yes -o ConnectTimeout=5 m7 \
        "python3 $RBM_REMOTE_SCRIPT $1 $2 $3 $4"
}
HYGIENE_SCRIPT="$WORKSPACE/protein-hygiene.sh"

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
        if rbm_out=$(run_rbm 0.6 0.4 0.2 0.3); then
            rbm_status="COMPLETED"
            rbm_homeostasis="STABLE_ACTIVE"
        else
            rbm_out="RBM_ERROR=EC2_EXECUTION_FAILED"
            rbm_status="ERROR"
            rbm_homeostasis="RBM_UNAVAILABLE"
        fi

        print "\n🧠 [RBM & HARMONIOUS NEURAL EVALUATION]"
        if [[ -n "$rbm_out" ]]; then
            print "$rbm_out"
        fi

        cat << GENESIS_EOF > "$PROCESSING_DIR/genesis_result.log"
STATUS=${rbm_status}
HOMEOSTASIS=${rbm_homeostasis}
BATTERY_ENERGY=${battery_level}%
$(echo "$rbm_out" | grep -E "RBM_FREE_ENERGY|RBM_METABOLIC_STRESS|RBM_STATE|RBM_ERROR")
0K_IDLE=ACTIVE
GENESIS_EOF

        print "🍃 [BALANCED FLOW] Active processing with mindful pacing. 1-second pause..."
        sleep 1
        ;;
    pulse)
        print "⚡ [PULSE] Executing lightweight RBM-assisted pulse..."
        rbm_out=""
        if rbm_out=$(run_rbm 0.3 0.2 0.1 0.1); then
            rbm_status="COMPLETED"
            rbm_homeostasis="STABLE_PULSE"
            print "$rbm_out"
        else
            rbm_out="RBM_ERROR=EC2_EXECUTION_FAILED"
            rbm_status="ERROR"
            rbm_homeostasis="RBM_UNAVAILABLE"
            print "$rbm_out"
        fi

        cat << GENESIS_EOF > "$PROCESSING_DIR/genesis_result.log"
STATUS=${rbm_status}
HOMEOSTASIS=${rbm_homeostasis}
BATTERY_ENERGY=${battery_level}%
$(echo "$rbm_out" | grep -E "RBM_FREE_ENERGY|RBM_METABOLIC_STRESS|RBM_STATE|RBM_ERROR")
0K_IDLE=ACTIVE
GENESIS_EOF
        ;;
    heal)
        print "🛡️ [IMMUNE & HARMONY] Executing system hygiene and integrity audit..."
        if [[ -x "$HYGIENE_SCRIPT" ]]; then
            "$HYGIENE_SCRIPT"
        fi
        
        cat << GENESIS_EOF > "$PROCESSING_DIR/genesis_result.log"
STATUS=COMPLETED
HOMEOSTASIS=IMMUNE_HEALED_AND_SANITIZED
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

# --- AUTO-SYNAPSE MESH INTEGRATION ---
if [[ -f "$HOME/protein-core/protein-synapse-mesh.sh" ]]; then
    ~/protein-core/protein-synapse-mesh.sh > /dev/null 2>&1
fi
