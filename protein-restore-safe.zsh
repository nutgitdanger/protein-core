#!/data/data/com.termux/files/usr/bin/zsh
# protein-restore-safe.zsh
# กู้คืนแบบเช็ก → เทียบ → แสดงผล → ต้องยืนยันก่อนแตะของจริง

set -u
setopt NO_NOMATCH

BACKUP="$HOME/dynu-audit-backup-20260916_033249.tar.gz"
ROOT="$HOME/.config/dynu-audit"
LAB="$HOME/protein-lab"
RESTORE_TMP="$HOME/restore-tmp-$$"
STAMP="$(date +%Y%m%d_%H%M%S)"
PRE_BACKUP="$HOME/dynu-audit-pre-restore-$STAMP.tar.gz"

echo "============================================================"
echo " PROTEIN RESTORE — SAFE MODE (เช็ก + เทียบ ก่อนรัน)"
echo "============================================================"
echo "BACKUP      : $BACKUP"
echo "ROOT        : $ROOT"
echo "LAB         : $LAB"
echo "RESTORE_TMP : $RESTORE_TMP"
echo

# ------------------------------------------------------------
# 1. PRECHECK
# ------------------------------------------------------------
echo "[1/8] PRECHECK"

if [[ ! -f "$BACKUP" ]]; then
    echo "FAIL: ไม่พบ backup → $BACKUP"
    exit 1
fi
echo "  BACKUP=OK  size=$(stat -c %s "$BACKUP" 2>/dev/null || echo ?)"

if [[ ! -d "$HOME" ]]; then
    echo "FAIL: HOME ไม่พร้อม"
    exit 1
fi
echo "  HOME=OK"

# ------------------------------------------------------------
# 2. สำรองของปัจจุบัน (กันพัง)
# ------------------------------------------------------------
echo
echo "[2/8] PRE-BACKUP ของปัจจุบัน"

tar -czf "$PRE_BACKUP" \
    -C "$HOME" \
    .config/dynu-audit protein-lab 2>/dev/null || true

if [[ -f "$PRE_BACKUP" ]]; then
    echo "  PRE_BACKUP=OK → $PRE_BACKUP"
else
    echo "  PRE_BACKUP=SKIP (ไม่มีของเดิม หรือสิทธิ์ไม่พอ)"
fi

# ------------------------------------------------------------
# 3. แตก backup ไปที่ชั่วคราว
# ------------------------------------------------------------
echo
echo "[3/8] EXTRACT ไป temporary"

rm -rf "$RESTORE_TMP"
mkdir -p "$RESTORE_TMP"

tar -xzf "$BACKUP" -C "$RESTORE_TMP" 2>/dev/null
if [[ $? -ne 0 ]]; then
    echo "FAIL: แตก tar ไม่สำเร็จ"
    exit 1
fi
echo "  EXTRACT=OK"

# หา path จริงภายใน tar
echo "  โครงสร้างภายใน backup:"
find "$RESTORE_TMP" -maxdepth 3 -type d | head -30

# ------------------------------------------------------------
# 4. หา canonical source ภายใน tar
# ------------------------------------------------------------
echo
echo "[4/8] หา SOURCE จริงใน backup"

SOURCE=""
if [[ -d "$RESTORE_TMP/.config/dynu-audit" ]]; then
    SOURCE="$RESTORE_TMP/.config/dynu-audit"
elif [[ -d "$RESTORE_TMP/dynu-audit" ]]; then
    SOURCE="$RESTORE_TMP/dynu-audit"
elif [[ -d "$RESTORE_TMP/home" ]]; then
    # กรณี tar จาก path เต็ม
    SOURCE=$(find "$RESTORE_TMP" -type d -name "dynu-audit" | head -1)
else
    SOURCE=$(find "$RESTORE_TMP" -type d -name "dynu-audit" | head -1)
fi

if [[ -z "$SOURCE" || ! -d "$SOURCE" ]]; then
    echo "FAIL: หา dynu-audit ใน backup ไม่เจอ"
    echo "  ลองดูด้วย: find $RESTORE_TMP -type d | head -50"
    exit 1
fi
echo "  SOURCE=$SOURCE"

# ------------------------------------------------------------
# 5. เทียบไฟล์สำคัญ (ก่อนแตะ)
# ------------------------------------------------------------
echo
echo "[5/8] เทียบไฟล์สำคัญ (DIFF CHECK)"

IMPORTANT=(
    protein-nib.sh
    protein-folding-engine.sh
    protein-master-status.sh
    protein-full-system-blueprint.sh
    protein-governor.sh
    protein-cycle.sh
    protein-dry-run.sh
)

echo "  ไฟล์ใน SOURCE vs ROOT ปัจจุบัน:"
for f in $IMPORTANT; do
    src="$SOURCE/$f"
    dst="$ROOT/$f"

    if [[ -f "$src" ]]; then
        src_hash=$(sha256sum "$src" 2>/dev/null | awk '{print $1}')
        src_size=$(stat -c %s "$src" 2>/dev/null || echo 0)
    else
        src_hash="MISSING"
        src_size=0
    fi

    if [[ -f "$dst" ]]; then
        dst_hash=$(sha256sum "$dst" 2>/dev/null | awk '{print $1}')
        dst_size=$(stat -c %s "$dst" 2>/dev/null || echo 0)
    else
        dst_hash="MISSING"
        dst_size=0
    fi

    if [[ "$src_hash" == "$dst_hash" ]]; then
        status="SAME"
    elif [[ "$src_hash" == "MISSING" ]]; then
        status="SRC_MISSING"
    elif [[ "$dst_hash" == "MISSING" ]]; then
        status="DST_MISSING → จะกู้"
    else
        status="DIFFER"
    fi

    printf "  %-35s  SRC=%-8s  DST=%-8s  %s\n" "$f" "$src_size" "$dst_size" "$status"
done

# ------------------------------------------------------------
# 6. แสดงแผนการกระทำ (ยังไม่ทำ)
# ------------------------------------------------------------
echo
echo "[6/8] แผนการกระทำ (DRY-RUN)"

echo "  จะทำสิ่งต่อไปนี้ถ้าคุณยืนยัน:"
echo "    1. rsync -a --delete-after จาก SOURCE → $ROOT"
echo "    2. ตรวจ lab layer ($LAB)"
echo "    3. สร้าง symlink สำคัญถ้าหาย"
echo "    4. รัน protein-master-status.sh หลังกู้"
echo
echo "  จะไม่ทำ:"
echo "    - ลบไฟล์นอก ROOT"
echo "    - แตะ credential / .ssh / token"
echo "    - auto-kill process"

# ------------------------------------------------------------
# 7. ยืนยันก่อนแตะของจริง
# ------------------------------------------------------------
echo
echo "[7/8] ยืนยันก่อนรันจริง"
echo -n "พิมพ์  YES  แล้วกด Enter เพื่อดำเนินการจริง (อย่างอื่น = ยกเลิก): "
read confirm

if [[ "$confirm" != "YES" ]]; then
    echo
    echo "ยกเลิกแล้ว — ไม่ได้แตะของจริง"
    echo "temporary ยังอยู่ที่: $RESTORE_TMP"
    echo "pre-backup อยู่ที่: $PRE_BACKUP"
    exit 0
fi

# ------------------------------------------------------------
# 8. ลงมือกู้ (หลังยืนยัน)
# ------------------------------------------------------------
echo
echo "[8/8] กำลังกู้คืนจริง..."

mkdir -p "$ROOT"
rsync -a --info=progress2 "$SOURCE/" "$ROOT/"

echo
echo "  ตรวจ lab layer..."
if [[ -d "$LAB" ]]; then
    echo "  LAB มีอยู่แล้ว"
else
    echo "  LAB หาย → สร้างโครงว่าง"
    mkdir -p "$LAB"
fi

# ตรวจไฟล์สำคัญหลังกู้
echo
echo "  ตรวจหลังกู้:"
for f in $IMPORTANT; do
    if [[ -f "$ROOT/$f" ]]; then
        echo "  OK  $f"
    else
        echo "  MISSING  $f"
    fi
done

# รัน status ถ้ามี
if [[ -x "$ROOT/protein-master-status.sh" ]]; then
    echo
    echo "  รัน protein-master-status.sh..."
    "$ROOT/protein-master-status.sh" || true
fi

echo
echo "============================================================"
echo " RESTORE COMPLETE"
echo "============================================================"
echo "PRE_BACKUP   : $PRE_BACKUP"
echo "RESTORE_TMP  : $RESTORE_TMP  (ลบเองทีหลังได้)"
echo "ROOT         : $ROOT"
echo
echo "แนะนำตรวจเพิ่ม:"
echo "  ls -la $ROOT/protein-*.sh"
echo "  sha256sum $ROOT/protein-*.sh | head"
echo "  $ROOT/protein-master-status.sh"
echo "============================================================"
