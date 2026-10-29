#!/usr/bin/env zsh
# protein-fold-lineage.sh: พับประวัติศาสตร์และอัปเดตรหัสพันธุกรรมแบบคล่องตัว (Clean & Rebuild)

DNA_FILE="protein-dna.sh"
TRACE_LOG="evidence/lineage-trace.log"

echo "🧬 กำลังพับและเคลียร์รหัสพันธุกรรมให้สะอาด..."

CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown-mutation")
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# เขียนโครงสร้าง DNA พื้นฐานใหม่แบบเอี่ยมอ่อง ตัดขยะทิ้งทั้งหมด
cat << EOF_DNA > "$DNA_FILE"
#!/usr/bin/env zsh
# protein-dna.sh: รหัสพันธุกรรมหลักของระบบโปรตีน (Clean Core DNA)

export PROTEIN_CORE_VERSION="2.0-clean"
export PROTEIN_STATE="active"

# --- ACTIVE LINEAGE ---
# Last Folded: $TIMESTAMP
# Root Commit: $CURRENT_COMMIT
# Status: Streamlined and healthy.
EOF_DNA

# บันทึกหลักฐานลง Log กลาง
echo "[$TIMESTAMP] Streamlined fold (Commit: $CURRENT_COMMIT) into DNA." >> "$TRACE_LOG"

echo "✅ พับรากสำเร็จ! DNA สะอาดเอี่ยมและปราดเปรียวแล้ว 🧬⚡️"
