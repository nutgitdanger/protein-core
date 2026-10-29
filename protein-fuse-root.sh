#!/usr/bin/env zsh
# protein-fuse-root.sh: ดึงรากต้นแบบดั้งเดิมจาก Git มาถักทอรวมกับ DNA ปัจจุบัน

DNA_FILE="protein-dna.sh"
TRACE_LOG="evidence/lineage-trace.log"

echo "🧬 กำลังค้นหาและดึงรากพันธุกรรมต้นแบบจาก Git History..."

# 1. หาคอมมิตแรกสุด (Root Commit) ของโปรเจกต์นี้
ROOT_COMMIT=$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -n 1)
CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown-mutation")
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

if [[ -z "$ROOT_COMMIT" ]]; then
    ROOT_COMMIT="genesis-origin"
else
    ROOT_COMMIT=$(echo "$ROOT_COMMIT" | cut -c1-7)
fi

# 2. สร้าง DNA ใหม่ที่ผสาน "รากดั้งเดิม" เข้ากับ "สถานะปัจจุบัน"
cat << EOF_DNA > "$DNA_FILE"
#!/usr/bin/env zsh
# protein-dna.sh: Unified Core DNA (Fused with Original Root)

export PROTEIN_CORE_VERSION="2.1-fused"
export PROTEIN_STATE="active"
export PROTEIN_ROOT_ANCESTOR="$ROOT_COMMIT"

# --- EVOLUTIONARY LINEAGE ---
# Root Ancestor (จุดกำเนิด): $ROOT_COMMIT
# Current Mutation (วิวัฒนาการล่าสุด): $CURRENT_COMMIT
# Last Fused: $TIMESTAMP
# Status: Streamlined, clean, yet anchored to true origin.
EOF_DNA

# 3. บันทึกหลักฐานการหลอมรวมลง Log
echo "[$TIMESTAMP] Fused root ancestor ($ROOT_COMMIT) with current mutation ($CURRENT_COMMIT) into DNA." >> "$TRACE_LOG"

echo "✅ หลอมรวมรากสำเร็จ! ตอนนี้โปรตีนตัวนี้มีทั้งความสะอาดและความทรงจำจากบรรพบุรุษดั้งเดิมแล้ว 🧬⚡️"
