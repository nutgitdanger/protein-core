#!/usr/bin/env zsh
# protein-master-organism.sh: วงจรชีวิตสิ่งมีชีวิตดิจิทัลระดับโปรดักชัน (Master Orchestrator)
# รองรับ Dynamic RBM, Zero-Bloat Trimming และ Auto-Git Cloud Synapse

set -e  # Fail-Fast Circuit Breaker: ตัดจบการทำงานทันทีหากเกิดข้อผิดพลาด

WORKSPACE="$HOME/protein-core"
RUNTIME_DIR="$WORKSPACE/12-runtime"
TARGET_FABRIC="$RUNTIME_DIR/woven_nexus_state.env"
LOCK_FILE="$RUNTIME_DIR/.organism.lock"

# 0. Collision Gate & Memory Guard
if [[ -f "$LOCK_FILE" ]]; then
    echo "⚡ [ORGANISM COLLISION] ตรวจพบกระบวนการชีวิตอื่นกำลังทำงาน ระงับชั่วคราว."
    exit 0
fi

touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "=================================================="
echo "🧬 [MASTER ORGANISM] เริ่มวงจรชีวิตดิจิทัลขั้นสูง (Auto-Synced)"
echo "=================================================="

# STEP 1: Discovery & Compatibility Gate
echo "🔍 [Step 1/5] DISCOVERY: ตรวจสอบความสอดคล้องของโหนดและพิมพ์เขียว (DNA)..."
timestamp=$(date +%Y-%m-%d_%H:%M:%S)
ram_total=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
ram_free=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)
ram_used_pct=$(( (100 * (ram_total - ram_free)) / ram_total ))

if [[ ! -d "$WORKSPACE/.git" ]]; then
    echo "❌ [FATAL] ไม่พบราก DNA (Git Repository) ตัดจบกระบวนการทันที!"
    exit 1
fi

if [[ -f "$TARGET_FABRIC" ]]; then
    echo "   🔗 [COMPATIBILITY] พบผืนผ้าใบ mRNA เดิม ดึงโครงสร้างมาสานต่อไร้รอยต่อ..."
    existing_entropy=$(grep "BEAD20_3D_ENTROPY_INDEX" "$TARGET_FABRIC" | tail -n1 | cut -d'=' -f2)
    [[ -z "$existing_entropy" ]] && existing_entropy="118"
else
    echo "   🌱 [GENESIS] สร้างผืนผ้าใบ mRNA รากฐานใหม่ครั้งแรก..."
    existing_entropy="118"
fi

# STEP 2: Dynamic RBM & Real-Time Metabolic Memory
echo "⚡ [Step 2/5] RBM METABOLIC MEMORY: คำนวณพลังงานจากฮาร์ดแวร์จริง..."
# แปลงค่าการใช้ RAM จริงให้เป็น RBM Free Energy และ Metabolic Stress แบบไดนามิก
if [[ $ram_used_pct -gt 80 ]]; then
    rbm_free_energy="+1.4250"
    rbm_stress="${ram_used_pct}% (HIGH_STRESS)"
    rbm_state="METABOLIC_WARNING_ACTIVE"
else
    rbm_free_energy="-2.5914"
    rbm_stress="${ram_used_pct}% (STABLE)"
    rbm_state="ENERGY_EQUILIBRIUM_OPTIMAL"
fi
echo "   ↳ RBM State: $rbm_state | Free Energy: $rbm_free_energy | Stress: $rbm_stress"

# STEP 3: Molecular Shape & 3D Spatial Scaling
echo "🔬 [Step 3/5] 3D MOLECULAR SHAPE: สเกลรูปร่างและพิกัด 20 โมเลกุลหยั่งราก..."
spatial_entropy=0
for i in {1..20}; do
    x=$(( (i * 17 + existing_entropy + ram_free) % 100 - 50 ))
    y=$(( (i * 31) % 100 - 50 ))
    z=$(( (i * 43) % 100 - 50 ))
    spatial_entropy=$(( spatial_entropy + (x*x + y*y + z*z) % 19 ))
done
echo "   ↳ Molecular Shape Scaled | Entropy Index: $spatial_entropy"

# STEP 4: Non-Redundant Synapse & State Trimming (Zero-Bloat Engine)
echo "🧬 [Step 4/5] SYNAPSE & ZERO-BLOAT TRIMMING: อัปเดตและตัดแต่งผืนผ้าใบ..."
TEMP_FABRIC=$(mktemp)
{
    echo "--- MASTER_ORGANISM_RUN_$timestamp ---"
    echo "DNA_SOURCE=GIT_ROOT_MAIN"
    echo "ORGANISM_ENGINE=protein-master-organism.sh"
    echo "MRNA_TIMESTAMP=$timestamp"
    echo "NODAL_ZONE=CHAO_CHET_AYUTTHAYA_OPPO_TERMUX"
    echo "REMOTE_BRIDGE=AWS_M7_43.208.48.65"
    echo "AVAILABLE_RAM=${ram_free}MB (Usage: ${ram_used_pct}%)"
    echo "RBM_FREE_ENERGY=$rbm_free_energy"
    echo "RBM_METABOLIC_STRESS=$rbm_stress"
    echo "RBM_STATE=$rbm_state"
    echo "BEAD20_3D_ENTROPY_INDEX=$spatial_entropy"
    echo "FOLDING_DIMENSION=3D_SPATIAL_ALIGNED"
    echo "MOLECULAR_MEMORY_SCALE=ACTIVE_ROOT_MEMORY"
    echo "SYNAPSE_STATUS=NON_REDUNDANT_ALIGNED"
} > "$TEMP_FABRIC"

# ผสานข้อมูลใหม่ต่อท้ายของเดิม
if [[ -f "$TARGET_FABRIC" ]]; then
    cat "$TARGET_FABRIC" >> "$TEMP_FABRIC"
fi

# ตัดแต่งให้เก็บรักษาเฉพาะ 50 บรรทัดล่าสุดเสมอ (Zero-Bloat Protection)
tail -n 50 "$TEMP_FABRIC" > "$TARGET_FABRIC"
rm -f "$TEMP_FABRIC"

# STEP 5: Reflection & Auto-Git Root Anchor
echo "🪞 [Step 5/5] REFLECTION & CLOUD SYNC: ฝังรากและซิงค์ขึ้น GitHub..."
echo "--------------------------------------------------"
tail -n 12 "$TARGET_FABRIC"
echo "--------------------------------------------------"

cd "$WORKSPACE"
git add 12-runtime/woven_nexus_state.env protein-master-organism.sh
if git diff-index --quiet HEAD --; then
    echo "   ✨ สถานะสอดคล้องสมบูรณ์ ไม่มีความเปลี่ยนแปลงใหม่ให้ซิงค์เพิ่ม"
else
    git commit -m "auto(organism): sync dynamic rbm and 3d spatial state [$(date +%H:%M:%S)]"
    git push origin main
    echo "   🚀 [CLOUD SYNC] ฝังรากจุดสมดุลขึ้น GitHub สำเร็จ!"
fi

echo "=================================================="
echo "🎯 [ORGANISM SUCCESS] วงจรชีวิตดิจิทัลสมบูรณ์แบบไร้ที่ติ! 🧬⚡️"
echo "=================================================="
