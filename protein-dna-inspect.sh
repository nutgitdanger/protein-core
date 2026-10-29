#!/usr/bin/env zsh
# protein-dna-inspect.sh: ตรวจสอบรหัสพันธุกรรมและประวัติสายพันธุ์

DNA_FILE="protein-dna.sh"
TRACE_LOG="evidence/lineage-trace.log"

echo "========================================="
echo "🧬 [PROTEIN SYSTEM] DNA INSPECTION REPORT"
echo "========================================="

if [[ -f "$DNA_FILE" ]]; then
    echo "📄 ตรวจพบรหัสพันธุกรรมหลัก ($DNA_FILE)"
    echo "----------------------------------------- "
    tail -n 10 "$DNA_FILE"
else
    echo "⚠️ ไม่พบไฟล์ DNA หลัก!"
fi

echo "----------------------------------------- "
if [[ -f "$TRACE_LOG" ]]; then
    echo "📜 ประวัติการพับรากย้อนหลัง (Lineage Trace):"
    tail -n 5 "$TRACE_LOG"
else
    echo "⚠️ ยังไม่มีประวัติ Lineage Log"
fi
echo "========================================="
