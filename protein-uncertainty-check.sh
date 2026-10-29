#!/usr/bin/env zsh
# protein-uncertainty-check.sh: ตรวจสอบความสอดคล้องของระบบภายใต้ขอบเขตความไม่แน่นอน

echo "=================================================="
echo "🔬 [PROTEIN SYSTEM] UNCERTAINTY & CONSISTENCY AUDIT"
echo "=================================================="

DNA_FILE="protein-dna.sh"
TRACE_LOG="evidence/lineage-trace.log"

# 1. ตรวจสอบความสอดคล้องของรหัสพันธุกรรม (DNA Integrity Check)
if [[ -f "$DNA_FILE" ]]; then
    ROOT_ANC=$(grep "PROTEIN_ROOT_ANCESTOR" "$DNA_FILE" | cut -d'"' -f2)
    echo "🧬 รากบรรพบุรุษที่บันทึกไว้ใน DNA : [${ROOT_ANC:-UNKNOWN}]"
    
    REAL_ROOT=$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -n 1 | cut -c1-7)
    echo "🌳 รากบรรพบุรุษจริงจาก Git History : [${REAL_ROOT:-UNKNOWN}]"
    
    if [[ "$ROOT_ANC" == "$REAL_ROOT" ]]; then
        echo "✅ [DNA CONSISTENCY]: สมบูรณ์ตรงกันภายใต้กรอบความไม่แน่นอนของเวลา"
    else
        echo "⚠️ [DNA DRIFT DETECTED]: ตรวจพบความเหลื่อมล้ำของรากเหง้า!"
    fi
else
    echo "❌ [FATAL]: ไม่พบรหัสพันธุกรรมหลัก!"
fi

echo "--------------------------------------------------"

# 2. ตรวจสอบความแปรปรวนของไฟล์ (Workspace Variance / Drift)
MODIFIED_COUNT=$(git status --porcelain | wc -l)
echo "📊 จำนวนไฟล์ที่เกิดความแปรปรวน (Modified/Untracked): $MODIFIED_COUNT ไฟล์"

if [[ "$MODIFIED_COUNT0" -le 3 ]]; then
    echo "🟢 [VARIANCE STATUS]: อยู่ในเกณฑ์ควบคุมได้ (Low Uncertainty Window)"
else
    echo "🟡 [VARIANCE STATUS]: มีความผันผวนสูง ควรพับรากหรือคอมมิตเก็บสถานะ"
fi

echo "=================================================="
echo "🔍 ตรวจสอบความสอดคล้องภายใต้ความไม่แน่นอนเสร็จสิ้น 🧬⚡️"
