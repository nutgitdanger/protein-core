#!/usr/bin/env bash
# runbook.sh: คำสั่งรันบุ๊กโครงการ
# หลักการ: ไม่ลบไฟล์, ไม่ push, ไม่แตะ AWS/GitHub, การแก้ไขต้องใส่ --apply
set -u
cd "$(dirname "$0")/.." || exit 1
DATE="$(date +%Y%m%d-%H%M)"
DL=/sdcard/Download
QDIR="$DL/_quarantine-$(date +%Y%m%d)"
TMPF="$HOME/.runbook-md5.txt"
BK="$HOME/runbook-backup"

hr()  { echo "----------------------------------------"; }
die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
cat <<'USAGE'
วิธีใช้: bash tools/runbook.sh <คำสั่ง> [--apply]

  status       ดูสถานะ git และ guard ของสคริปต์ (อ่านอย่างเดียว)
  secure       ตรวจความปลอดภัยเบื้องต้น (อ่านอย่างเดียว)
  guard-vault  เพิ่ม guard ให้ protein-aws-vault-upgrade.sh (dry-run ถ้าไม่ใส่ --apply)
  root         เขียน ROOT.md ฉบับเต็มและ commit ในเครื่อง (dry-run ถ้าไม่ใส่ --apply)
  check        รัน tools/check.sh
  space        ดูแรม swap และพื้นที่ (อ่านอย่างเดียว)
  dupes        หาไฟล์ซ้ำใน Download; --apply ย้ายสำเนาไปโฟลเดอร์กักกัน (ไม่ลบ)
  manual       พิมพ์รายการที่ต้องทำเองบนเว็บ
USAGE
}

cmd_status() {
  hr; echo "[git]"
  git --no-pager status --short
  git --no-pager log --oneline -1
  hr; echo "[commit ที่ยังไม่อยู่บน origin/main]"
  git --no-pager log --oneline origin/main..HEAD 2>/dev/null || echo "(ไม่มีข้อมูล origin/main)"
  hr; echo "[ไฟล์สำคัญ]"
  for f in ROOT.md tools/bead_check.py tools/check.sh; do
    if [ -f "$f" ]; then echo "OK      $f"; else echo "MISSING $f"; fi
  done
  hr; echo "[guard ALLOW_PUSH]"
  for f in protein-master-organism.sh protein-paper-synapse.sh protein-reconcile.sh protein-aws-vault-upgrade.sh; do
    if [ ! -f "$f" ]; then echo "NOFILE  $f"
    elif grep -q 'ALLOW_PUSH' "$f"; then echo "GUARD   $f"
    else echo "NOGUARD $f"; fi
  done
}

cmd_secure() {
  hr; echo "[SSH]"
  if ls ~/.ssh 2>/dev/null | grep -qE '^id_'; then
    echo "พบ private key ใน ~/.ssh (ลบถ้าไม่ได้ใช้)"
  else
    echo "ไม่มี private key ใน ~/.ssh"
  fi
  if pgrep -x sshd >/dev/null 2>&1; then echo "sshd กำลังทำงาน (ตรวจว่าจำเป็นหรือไม่)"
  else echo "sshd ไม่ทำงาน"; fi
  if [ -s ~/.ssh/authorized_keys ]; then
    echo "authorized_keys มี $(wc -l < ~/.ssh/authorized_keys) บรรทัด ตรวจว่ารู้จักทุก key"
  else
    echo "authorized_keys ว่าง"
  fi
  hr; echo "[gh]"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "gh ยังล็อกอินอยู่ (รัน gh auth logout เมื่อใช้เสร็จ)"
  else
    echo "gh ออกจากระบบแล้ว หรือยังไม่ได้ติดตั้ง"
  fi
  hr; echo "[AWS]"
  if [ -f ~/.aws/credentials ]; then
    echo "พบ ~/.aws/credentials (ไม่แสดงเนื้อหา) ตรวจใน IAM ว่า key ไหนยัง active"
  else
    echo "ไม่พบ ~/.aws/credentials"
  fi
  hr; echo "[pattern ความลับในไฟล์ที่ track (แสดงเฉพาะชื่อไฟล์)]"
  git grep -lE 'AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|aws_secret_access_key' || echo "ไม่พบ"
  hr; echo "[ไฟล์ที่ชื่อบ่งว่าเป็นความลับ ใน history]"
  git --no-pager log --all --name-only --format= | sort -u | grep -iE '\.pem$|\.env$|credentials|id_rsa|\.key$' || echo "ไม่พบ"
}

cmd_guard_vault() {
  local f=protein-aws-vault-upgrade.sh
  [ -f "$f" ] || die "ไม่พบ $f"
  if grep -q 'ALLOW_PUSH' "$f"; then echo "guard มีอยู่แล้ว ไม่ทำซ้ำ"; return 0; fi
  echo "คำสั่งที่เสี่ยงในไฟล์นี้:"
  grep -nE 'git push|git commit|aws |rm |mv |curl |ssh ' "$f" || echo "(ไม่พบ)"
  if [ "${1:-}" != "--apply" ]; then
    echo "dry-run: รันด้วย --apply เพื่อเพิ่ม guard (สำรองไฟล์เดิมไว้ที่ $BK)"
    return 0
  fi
  mkdir -p "$BK"
  cp "$f" "$BK/$(basename "$f").$DATE" || die "สำรองไม่สำเร็จ"
  sed -i '1a [ "${ALLOW_PUSH:-0}" = "1" ] || { echo "auto-push ปิดอยู่"; exit 0; }' "$f"
  local checker=bash
  head -1 "$f" | grep -q zsh && checker=zsh
  if "$checker" -n "$f"; then
    echo "OK: เพิ่ม guard แล้ว (สคริปต์จะจบทันทีถ้าไม่ตั้ง ALLOW_PUSH=1)"
  else
    cp "$BK/$(basename "$f").$DATE" "$f"
    die "ตรวจไวยากรณ์ไม่ผ่าน คืนไฟล์เดิมแล้ว"
  fi
}

cmd_root() {
  if [ "${1:-}" != "--apply" ]; then
    echo "dry-run: จะเขียน ROOT.md ฉบับเต็มและ commit ในเครื่อง รันด้วย --apply เพื่อยืนยัน"
    return 0
  fi
  mkdir -p "$BK"
  [ -f ROOT.md ] && cp ROOT.md "$BK/ROOT.md.$DATE"
  cat > ROOT.md <<'ROOT_EOF'
# ROOT: จุดอ้างอิงเดียวของโครงการ

## เป้าหมาย (เดียว)
เทียบโครงสร้างที่ทำนายของ ubiquitin (UniProt P62988, ยืนยันบน uniprot.org ก่อนใช้)
กับโครงสร้างจากการทดลอง 1UBQ วัดด้วย RMSD บนกรดอะมิโนที่ pLDDT > 70 เท่านั้น
เป้าอื่นทั้งหมดเป็นของรอง จนกว่าเป้านี้จะผ่าน

## แกนหลัก
- repo ที่ใช้งาน: nutgitdanger/protein-core
- สาขาทำงาน: foundation (ห้ามทำบน main)
- อ้างอิงเท่านั้น (ไม่รันคู่กัน): protein-lite, dynu-audit, nutdata

## กติกา
1. สคริปต์ที่ push ต้องตั้ง ALLOW_PUSH=1 เท่านั้น
2. ส่วนประกอบใหม่ต้องมีแถวในตารางนี้ก่อนรัน
3. ผลทดสอบต้องมาจากการรันจริง ไม่ใช่ข้อความตายตัว
4. ทุกการเปลี่ยนแปลงผ่าน commit บน foundation แล้วเปิด PR
5. ก่อน merge ต้องรัน tools/check.sh ให้ผ่าน

## สถานะ (อัปเดตด้วยมือ)
- 2026-11-01: foundation ตรงกับ GitHub ที่ 88e16c8 main อยู่ที่ 241eee9 ไม่ถูกแตะ
- สคริปต์ auto-push สามตัวปิดด้วย guard แล้ว
- protein-guardian-ec2.sh, protein-pipeline-engine.sh ย้ายไป _archive/ รอรีวิว
- ยังไม่เคยทดลองพับโปรตีนจริง ผลที่ผ่านมาเป็นการตรวจโครงสร้างระบบ
- ค้าง: bead_check.py ยังไม่ได้ทดสอบกับข้อมูลที่รู้คำตอบ
- ค้าง: rotate access key ของ nut-dev
- ค้าง: protein-aws-vault-upgrade.sh ยังไม่รีวิว

## ส่วนประกอบ
| ชื่อ | ที่อยู่ | หน้าที่ | สถานะ |
|---|---|---|---|
| bead check | tools/bead_check.py | ตรวจการชนทุกคู่ ย้อนกลับถ้าการขยับทำให้แย่ลง | ทดสอบกับตัวอย่าง 3 จุดเท่านั้น |
| check | tools/check.sh | รวมการตรวจไว้ที่เดียว | ผ่านบนเครื่อง |
| rmsd | tools/rmsd_check.py | เทียบ CA หลัง superposition กรองด้วย pLDDT | ยังไม่รันกับข้อมูลจริง |
| runbook | tools/runbook.sh | คำสั่งรันบุ๊ก | ใช้ได้ |
| auto-pushers | protein-master-organism.sh, protein-paper-synapse.sh, protein-reconcile.sh | commit/push เอง | ปิดด้วย guard |
| vault upgrade | protein-aws-vault-upgrade.sh | เกี่ยวกับ AWS | ค้าง |

## บันทึกการตัดสินใจ
- 2026-11-01: เลือก foundation เป็นสาขาทำงาน เพราะ main มี auto-push ที่ยังไม่รีวิว
- 2026-11-01: untrack env และ cache ออกจาก git เพื่อไม่ให้สถานะการรันเข้า repo
- 2026-11-01: ยังไม่ลบ history ที่มี woven_nexus_state.env เพราะต้องคุยกันก่อน
ROOT_EOF
  if git add ROOT.md && git commit -qm "docs: ROOT status and single goal as of 2026-11-01"; then
    echo "OK: commit ROOT.md ในเครื่องแล้ว (ยังไม่ push)"
  else
    echo "ไม่มีการเปลี่ยนแปลงให้ commit"
  fi
}

cmd_space() {
  hr; echo "[แรมและ swap]"
  free -m 2>/dev/null | awk '
    /Mem:/  { printf "RAM   รวม %sM  ใช้ %sM  available %sM\n", $2, $3, $7 }
    /Swap:/ { if ($2 > 0) printf "Swap  รวม %sM  ใช้ %sM  (%d%%)\n", $2, $3, $3*100/$2 }'
  hr; echo "[พื้นที่ /data]"
  df -h /data 2>/dev/null | tail -1
}

cmd_dupes() {
  [ -d "$DL" ] || die "ไม่พบ $DL"
  md5sum "$DL"/Pasted*.txt > "$TMPF" 2>/dev/null || die "อ่าน md5 ไม่ได้"
  local plan
  plan="$(awk '
    { h = substr($0, 1, 32); p = substr($0, 35)
      if (p ~ /-[0-9]\.txt$/) copies[h] = copies[h] "\t" p
      else orig[h] = p }
    END {
      for (h in copies) {
        n = split(copies[h], a, "\t")
        for (i = 1; i <= n; i++) if (a[i] != "") {
          if (h in orig) print a[i] "\t" orig[h]
          else print "SKIP\t" a[i]
        }
      }
    }' "$TMPF")"
  hr
  if [ -z "$plan" ]; then echo "ไม่พบสำเนาที่มีต้นฉบับ"; return 0; fi
  echo "สำเนา <TAB> ต้นฉบับ  (SKIP = ไม่มีต้นฉบับ จะไม่ย้าย)"
  echo "$plan"
  echo "จำนวนสำเนาที่จะย้าย: $(echo "$plan" | grep -vc '^SKIP')"
  if [ "${1:-}" != "--apply" ]; then
    echo "dry-run: รันด้วย --apply เพื่อย้ายไป $QDIR (ไม่ลบ)"
    return 0
  fi
  mkdir -p "$QDIR" || die "สร้างโฟลเดอร์กักกันไม่ได้"
  echo "$plan" | while IFS=$'\t' read -r copy orig; do
    [ "$copy" = "SKIP" ] && continue
    [ -f "$orig" ] || { echo "ข้าม: ไม่พบต้นฉบับ $orig"; continue; }
    [ -f "$copy" ] || continue
    if [ "$(md5sum < "$copy")" != "$(md5sum < "$orig")" ]; then
      echo "ข้าม: เนื้อหาไม่ตรงกัน $copy"; continue
    fi
    mv -n "$copy" "$QDIR/" && echo "กักกัน: $(basename "$copy")"
  done
  echo "เสร็จ ตรวจโฟลเดอร์ $QDIR ก่อนตัดสินใจลบอะไร (อย่างน้อย 7 วัน)"
}

cmd_manual() {
cat <<'MANUAL'
ต้องทำเองบนเว็บ (สคริปต์ทำแทนไม่ได้):
1. AWS IAM > Users > nut-dev > Permissions: ถอด AdministratorAccess ถ้ามี
2. AWS IAM > nut-dev > Security credentials: สร้าง access key ใหม่, Deactivate key เก่า,
   ตรวจว่างานยังทำงาน แล้วค่อย Delete key เก่า (ห้ามวาง key ในแชท)
3. GitHub > Settings > SSH and GPG keys: ลบ key ชื่อ "GitHub CLI"
4. เปิด PR: https://github.com/nutgitdanger/protein-core/pull/new/foundation
   อย่า merge จนกว่า check ผ่าน, rmsd ผ่านข้อมูลจริง, และ vault upgrade ถูกรีวิว
MANUAL
}

case "${1:-help}" in
  status)      cmd_status ;;
  secure)      cmd_secure ;;
  guard-vault) cmd_guard_vault "${2:-}" ;;
  root)        cmd_root "${2:-}" ;;
  check)       bash tools/check.sh; echo "exit=$?" ;;
  space)       cmd_space ;;
  dupes)       cmd_dupes "${2:-}" ;;
  manual)      cmd_manual ;;
  *)           usage ;;
esac
