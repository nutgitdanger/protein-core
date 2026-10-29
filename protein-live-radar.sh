#!/usr/bin/env zsh
set -uo pipefail

WORKSPACE="$HOME/protein-core"
PIPELINE="$WORKSPACE/pipeline"

clear
echo "====================================================================="
echo "        🧬 PROTEIN ECOSYSTEM: LIVE SYSTEM RADAR & TOPOLOGY          "
echo "====================================================================="

# 1. Check Core State
echo "[📂 CORE METABOLIC & SHIELD STATE]"
if [[ -f "$WORKSPACE/metabolism.state" ]]; then
    echo "  • Metabolism State : $(cat $WORKSPACE/metabolism.state | tr '\n' ' ')"
else
    echo "  • Metabolism State : [MISSING / STALE]"
fi

if [[ -f "$WORKSPACE/shield.state" ]]; then
    echo "  • Shield Status    : $(cat $WORKSPACE/shield.state)"
else
    echo "  • Shield Status    : [INACTIVE]"
fi
echo "---------------------------------------------------------------------"

# 2. Check Pipeline Queue Status
echo "[⚙️ PIPELINE QUEUE FLOW]"
pending_cnt=$(ls -1 "$PIPELINE/pending" 2>/dev/null | wc -l)
processing_cnt=$(ls -1 "$PIPELINE/processing" 2>/dev/null | wc -l)
completed_cnt=$(ls -1 "$PIPELINE/completed" 2>/dev/null | wc -l)
failed_cnt=$(ls -1 "$PIPELINE/failed" 2>/dev/null | wc -l)

echo "  • Pending (รอคิว)      : $pending_cnt jobs"
echo "  • Processing (กำลังทำ) : $processing_cnt jobs"
echo "  • Completed (สำเร็จ)    : $completed_cnt jobs"
echo "  • Failed (ตกหล่น/พัง)   : $failed_cnt jobs"
echo "---------------------------------------------------------------------"

# 3. Check Active Processes
echo "[💻 ACTIVE RUNNING PROCESSES]"
active_procs=$(ps aux | grep -E "protein|dynu|master-controller" | grep -v grep | wc -l)
if (( active_procs > 0 )); then
    echo "  🟢 พบกระบวนการทำงานอยู่ ($active_procs processes):"
    ps aux | grep -E "protein|dynu|master-controller" | grep -v grep | awk '{print "     - PID:", $2, "CMD:", $11, $12}'
else
    echo "  ⚪ ไม่มีสคริปต์ Protein/Dynu รันค้างอยู่ (ระบบอยู่ในสถานะ 0K Idle)"
fi
echo "====================================================================="
echo "💡 คำแนะนำ: ใช้คำสั่ง './protein-live-radar.sh' เพื่อรีเฟรชดูภาพรวม"
