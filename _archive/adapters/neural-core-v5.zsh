#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

input_type="${1:-deep_5layer_audit}"
MEMORY_FILE="$HOME/protein-core/pipeline/.neural_memory"

# 1. กวาดความถี่ทั้ง 8 คอร์
cores_freq=()
for i in {0..7}; do
    local freq_file="/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq"
    if [[ -r "$freq_file" ]]; then
        local f=$(cat "$freq_file" 2>/dev/null)
        cores_freq+="${f:-0}"
    else
        cores_freq+="0"
    fi
done
core_string="${(j:,:)cores_freq}"

# อ่านค่าคะแนนรอบที่แล้วจากหน่วยความจำระยะสั้น (ถ้ามี)
prev_score=50.0
if [[ -r "$MEMORY_FILE" ]]; then
    prev_score=$(cat "$MEMORY_FILE" 2>/dev/null || echo "50.0")
fi

# 2. 5-LAYER DEEP NEURAL NETWORK WITH TEMPORAL MEMORY
result_metrics=$(awk -v data="$core_string" -v p_score="$prev_score" '
function sigmoid(z) {
    return 1.0 / (1.0 + exp(-z))
}
BEGIN {
    split(data, c, ",")
    
    # Normalize ทั้ง 8 คอร์ (0.0 - 1.0)
    for(i=1; i<=8; i++) {
        norm[i] = (c[i] + 0.0) / 2000000.0
        if (norm[i] > 1.0) norm[i] = 1.0
    }

    # --- LAYER 1: Feature Extraction ---
    L1_eff = sigmoid((norm[1]*0.25) + (norm[2]*0.25) + (norm[3]*0.25) + (norm[4]*0.25))
    L1_perf = sigmoid((norm[5]*0.25) + (norm[6]*0.25) + (norm[7]*0.25) + (norm[8]*0.25))

    # --- LAYER 2: Cross-Cluster Integration ---
    L2_mix1 = sigmoid((L1_eff * 0.7) + (L1_perf * 0.3))
    L2_mix2 = sigmoid((L1_perf * 0.7) + (L1_eff * 0.3))

    # --- LAYER 3: Metabolic Stress & Homeostasis ---
    L3_stress = sigmoid((L2_mix1 * 0.4) + (L2_mix2 * 0.6) - 0.5)

    # --- LAYER 4: Executive Decision ---
    base_score = ((L3_stress * 0.5) + (L2_mix2 * 0.5)) * 100.0

    # --- LAYER 5: Temporal Memory & Evolutionary Trend Layer (NEW!) ---
    # เปรียบเทียบคะแนนปัจจุบันกับอดีต เพื่อหาอัตราเร่ง (Momentum / Delta)
    trend = base_score - p_score
    L5_memory = sigmoid(trend * 0.1) # แปลงแนวโน้มให้อยู่ในรูปตัวคูณทางประสาท
    
    # คะแนนรวมที่ถูกกำกับด้วยความทรงจำระยะสั้น
    score = (base_score * 0.8) + (L5_memory * base_score * 0.2)

    # Multi-Tier Deep Routing with Memory Context
    if (score > 80.0) {
        route = "PREDICTIVE_THROTTLE_LOCK"
    } else if (score > 55.0) {
        route = "OPTIMIZED_HIGH_BANDWIDTH"
    } else if (score > 25.0) {
        route = "BALANCED_THROUGHPUT"
    } else {
        route = "DEEP_IDLE_CONSERVATION"
    }

    printf "L1_EFF=%.4f\nL1_PERF=%.4f\nL2_MIX1=%.4f\nL2_MIX2=%.4f\nL3_STRESS=%.4f\nL5_TREND=%.4f\nMETABOLIC_SCORE=%.2f%%\nROUTE=%s\n", L1_eff, L1_perf, L2_mix1, L2_mix2, L3_stress, trend, score, route
}')

# บันทึกคะแนนรอบนี้ลงหน่วยความจำระยะสั้นสำหรับรอบถัดไป
echo "$result_metrics" | grep "METABOLIC_SCORE" | awk -F'=' '{print $2}' | tr -d '%' > "$MEMORY_FILE"

# 3. GENERATE IDENTITY SHA
neural_sha="$(printf '%s:%s' "$core_string" "$result_metrics" | sha256sum | awk '{print $1}')"

# 4. READY OUTPUT
printf '=== 5-LAYER EVOLUTIONARY NEURAL PASS ===\n'
printf 'INPUT_TYPE=%s\n' "$input_type"
printf '%s\n' "$result_metrics"
printf 'NEURAL_SHA256=%s\n' "$neural_sha"
printf 'STATUS=READY\n'
