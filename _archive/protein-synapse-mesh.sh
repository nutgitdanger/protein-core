#!/data/data/com.termux/files/usr/bin/zsh
set -uo pipefail

WORKSPACE="$HOME/protein-core"
MEMORY_FILE="$WORKSPACE/pipeline/.neural_memory_history.json"
MESH_LOG="$WORKSPACE/pipeline/.synapse_broadcast"

print "🌐 [PROTEIN SYNAPSE MESH] Synchronizing neural experiences across layers..."

if [[ -f "$MEMORY_FILE" ]]; then
    # ดึงข้อมูลสถิติจากความทรงจำระยะยาวของ RBM มาแปลเป็น Experience Packet
    runs=$(grep -o '"total_runs": [0-9]*' "$MEMORY_FILE" | awk '{print $2}')
    avg_stress=$(grep -o '"avg_stress": [0-9.]*' "$MEMORY_FILE" | awk '{print $2}')
    bias=$(grep -o '"adaptive_bias": [-0-9.]*' "$MEMORY_FILE" | awk '{print $2}')
    
    cat << MESH_EOF > "$MESH_LOG"
[SYNAPSE BROADCAST PACKET]
TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
NODE_ID=OPPO_TERMUX_MT6771
TOTAL_EXPERIENCES=${runs:-0}
SHARED_AVG_STRESS=${avg_stress:-0.0}%
SYNAPTIC_BIAS=${bias:-0.0}
MESH_STATUS=HARMONIZED_AND_SHARED
MESH_EOF

    print "✅ [SYNAPSE SUCCESS] Neural experience packet broadcasted successfully!"
    cat "$MESH_LOG"
else
    print "⚠️ [SYNAPSE WARN] No neural memory found yet. Run 'pscan' first."
fi
