#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PROMPT="${*:-ภูเขาสูงท่ามกลางเมฆ ยามพระอาทิตย์ขึ้น แสงสีทอง}"
WROOT="$HOME/.config/dynu-audit/containers/protein"

echo "🖼️======================================"
echo "  PROTEIN EC2 — AI IMAGE CLUSTER"
echo "========================================"
echo "📝 พรอมต์: $PROMPT"
echo ""

# === ขั้นที่ 1: จำลองการเปิด EC2 Instance ===
echo "🖥️  [1/3] กำลังเตรียมเปิด EC2 Instance (image-worker)..."
bash protein-ec2.sh create image-worker t3.large 8

# === ขั้นที่ 2: รันงาน AI ภายใน Container ===
echo "🧠 [2/3] กำลังสร้างภาพผ่านระบบโปรตีน..."
proot-distro login debian --isolated \
  --bind "$WROOT:/worker" \
  -- /bin/bash -lc "
    cd /worker
    export PROMPT='$PROMPT'
    
    # ใช้ python จาก shared/venv โดยตรงเพื่อความชัวร์
    if [ -f \"shared/venv/bin/python3\" ]; then
        ./shared/venv/bin/python3 -c '
import os
print(\"🚀 Python AI Environment Ready via Shared Venv!\")
print(\"💡 Prompt:\", os.environ.get(\"PROMPT\"))
        '
    else
        python3 -c 'print(\"⚠️ Fallback to system python\")'
    fi
  "

# === ขั้นที่ 3: ปิด Instance อัตโนมัติ ===
echo "🛑 [3/3] ปิด EC2 Instance..."
bash protein-ec2.sh stop image-worker

echo ""
echo "✅======================================"
echo "  🎉 กระบวนการทำงานบน EC2 จำลองเสร็จสมบูรณ์!"
echo "========================================"
