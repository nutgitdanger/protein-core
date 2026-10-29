#!/usr/bin/env zsh
# protein-pulse-check.sh: ตรวจสอบชีพจรและการทำงานของโปรตีนในระบบ

echo "=================================================="
echo "💓 [PROTEIN SYSTEM] PULSE & DAEMON CHECK"
echo "=================================================="

# 1. เช็กกระบวนการ (Processes) ที่เกี่ยวข้องกับโปรตีนหรือไดนามิกส์ที่รันอยู่
echo "\n1. 🧬 Active Protein / Background Processes:"
ps aux | grep -E "protein|dynu|light_guard" | grep -v grep

# 2. เช็กสถานะของ Core DNA ล่าสุด
DNA_FILE="protein-dna.sh"
if [[ -f "$DNA_FILE" ]]; then
    echo "\n2. 📄 Current Core State:"
    grep -E "PROTEIN_CORE_VERSION|PROTEIN_STATE|PROTEIN_ROOT_ANCESTOR" "$DNA_FILE"
else
    echo "\n2. ⚠️ ไม่พบไฟล์ DNA หลัก!"
fi

# 3. เช็กสถานะ Git และความพร้อมของพื้นที่ทำงาน
echo "\n3. 🌳 Git Repository Pulse:"
git status -s
git log -1 --format="   - Last Commit: %h - %s (%an, %ar)"

echo "=================================================="
echo "✅ ตรวจสอบชีพจรระบบเสร็จสิ้น 🧬⚡️"
