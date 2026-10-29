#!/usr/bin/env zsh
set -uo pipefail

TARGET_DIR="$HOME/protein-core"
SEARCH_ROOT="$HOME"

echo "====================================================================="
echo "        🧬 PROTEIN UNIFICATION: PULLING ECOSYSTEM TO CORE"
echo "====================================================================="

mkdir -p "$TARGET_DIR/bin" "$TARGET_DIR/pipeline" "$TARGET_DIR/registry"

echo "🔍 [SCANNING] ค้นหาสคริปต์และส่วนประกอบโปรตีนทั่วทั้งระบบ..."

# ค้นหาไฟล์ .sh, .zsh, .py ทั้งหมดที่เกี่ยวข้องกับ protein หรือ dynu แล้วดึงมารวมศูนย์
find "$SEARCH_ROOT" -type f \( -name "protein-*.sh" -o -name "protein-*.zsh" -o -name "dynu-*.sh" -o -name "dynu-*.py" -o -name "protein-master-controller.zsh" \) 2>/dev/null | while read -r file; do
    filename=$(basename "$file")
    dest="$TARGET_DIR/$filename"
    
    # ถ้าไฟล์ยังไม่มีใน core หรือตัวใหม่กว่า ให้ก๊อปปี้มารวมไว้
    if [[ ! -f "$dest" ]] || [[ "$file" -nt "$dest" ]]; then
        # ยกเว้นตัวเองหรือ path ใน core อยู่แล้ว
        if [[ "$file" != "$TARGET_DIR/*" ]]; then
            cp -f "$file" "$dest"
            chmod +x "$dest" 2>/dev/null
            echo "  📥 รวมร่างสำเร็จ: $filename (จาก $file)"
        fi
    fi
done

echo "---------------------------------------------------------------------"
echo "✅ [SUCCESS] รวบรวมชิ้นส่วนโปรตีนทั้งหมดกลับมาไว้ที่: $TARGET_DIR"
echo "💡 คำแนะนำ: ใช้คำสั่ง 'll' เพื่อตรวจสอบชิ้นส่วนทั้งหมดที่ถูกดึงมารวมกัน"
echo "====================================================================="
