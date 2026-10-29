#!/bin/zsh
export PATH="$PREFIX/bin:/system/bin:/system/xbin"

# --- 1. ระบบป้องกันการรันทับซ้อน ---
LOCK_DIR="$HOME/.config/dynu-audit/containers/protein/.lock"
mkdir -p "$LOCK_DIR"
LOCK_FILE="$LOCK_DIR/protein-pipeline.lock"

if [ -f "$LOCK_FILE" ]; then
    echo "ปฏิเสธการรันทับซ้อน: Pipeline กำลังประมวลผลงานอื่นอยู่!"
    exit 1
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# --- 2. ตั้งค่าโปรตีนเป้าหมาย ---
PROTEIN_ID="${1:-P02751}"
WORK_DIR="$HOME/.config/dynu-audit/containers/protein/research/alphafold"
EVIDENCE_DIR="$HOME/.config/dynu-audit/containers/protein/research/evidence/alphafold-fetch"
ATTEMPT_DIR="$EVIDENCE_DIR/attempts"
mkdir -p "$WORK_DIR" "$ATTEMPT_DIR"

PDB_FILE="$WORK_DIR/${PROTEIN_ID}.pdb"
TMP_FILE="$WORK_DIR/.${PROTEIN_ID}.download.tmp"
ERROR_FILE="$EVIDENCE_DIR/${PROTEIN_ID}.fetch-error"

echo "🧬 [1/3] กำลังดึงข้อมูล AlphaFold ของโปรตีน (${PROTEIN_ID})..."

download_ok=false

for VERSION in v4 v6; do
    echo "→ ทดลอง AlphaFold ${VERSION}..."

    rm -f "$TMP_FILE"

    HTTP_CODE=$(
        curl -L -sS \
          -o "$TMP_FILE" \
          -w '%{http_code}' \
          "https://alphafold.ebi.ac.uk/files/AF-${PROTEIN_ID}-F1-model_${VERSION}.pdb"
    )

    SIZE=$(wc -c < "$TMP_FILE" 2>/dev/null || echo 0)

    # ต้องเป็น HTTP 2xx, มีขนาดพอสมควร และมี PDB ATOM/HEADER content
    if [[ "$HTTP_CODE" == 2* ]] && (( SIZE >= 1000 )) &&
       grep -qE '^(HEADER|ATOM  |MODEL |REMARK)' "$TMP_FILE" 2>/dev/null; then
        download_ok=true
        break
    fi

    {
        echo "PROTEIN_ID=$PROTEIN_ID"
        echo "VERSION=$VERSION"
        echo "HTTP_CODE=$HTTP_CODE"
        echo "SIZE=$SIZE"
        echo "VALID_PDB=false"
        echo
        cat "$TMP_FILE" 2>/dev/null
    } > "$ATTEMPT_DIR/${PROTEIN_ID}-${VERSION}.txt"

    rm -f "$TMP_FILE"
done

if [[ "$download_ok" != true ]]; then
    {
        echo "PROTEIN_ID=$PROTEIN_ID"
        echo "FINAL_STATUS=FETCH_FAILED"
        echo "VALID_PDB=false"
        echo "ATTEMPTS=v4,v6"
    } > "$ERROR_FILE"

    echo "❌ ไม่พบ AlphaFold PDB ที่ถูกต้องสำหรับ ${PROTEIN_ID}"
    echo "   Final failure evidence:"
    echo "   $ERROR_FILE"
    exit 1
fi

rm -f "$ERROR_FILE"

# เขียนทับ PDB จริงเฉพาะหลัง validation ผ่าน
mv "$TMP_FILE" "$PDB_FILE"

echo "✅ ดาวน์โหลดและตรวจสอบ PDB สำเร็จ!"
echo "   ไฟล์: $PDB_FILE"
echo "   ขนาด: $(wc -c < "$PDB_FILE") bytes"

# --- 3. วิเคราะห์โครงสร้าง ---
echo "🔍 [2/3] กำลังสแกนหาโดเมนและข้อต่อเส้นใยลูกปัด (Linkers)..."

python3 -c '
from pathlib import Path
import sys

pdb_path = sys.argv[1]
atoms = []

with open(pdb_path, "r") as f:
    for line in f:
        if line.startswith("ATOM") and line[12:16].strip() == "CA":
            res_seq = int(line[22:26].strip())
            plddt = float(line[60:66].strip())
            atoms.append((res_seq, plddt))

print(f"📊 จำนวนกรดอะมิโนทั้งหมด: {len(atoms)} ตัว")

linkers = []
start_linker = None

for res_seq, plddt in atoms:
    if plddt < 70:
        if start_linker is None:
            start_linker = res_seq
    else:
        if start_linker is not None:
            if res_seq - start_linker >= 3:
                linkers.append((start_linker, res_seq - 1))
            start_linker = None

if start_linker is not None and atoms:
    last_res = atoms[-1][0]
    if last_res - start_linker >= 3:
        linkers.append((start_linker, last_res))

print(f"✨ [3/3] พบโซนข้อต่อ (Linkers) ทั้งหมด {len(linkers)} จุด!")

if linkers:
    print("   ตัวอย่างโซนข้อต่อ:")
    for start, end in linkers[:5]:
        print(f"   - ตำแหน่งกรดอะมิโนที่ {start} ถึง {end}")
' "$PDB_FILE"

echo "🎉 กระบวนการทั้งหมดเสร็จสิ้นอย่างสมบูรณ์!"
