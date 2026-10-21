#!/data/data/com.termux/files/usr/bin/zsh
set -uo pipefail

WORKSPACE="$HOME/protein-core"
QUARANTINE_DIR="$WORKSPACE/12-runtime/conveyor/processing/quarantine_$(date +%Y%m%d_%H%M%S)"

print "🛡️ [PROTEIN HYGIENE] Initiating system file audit & deduplication scan..."

# สร้างโฟลเดอร์กักกัน (Quarantine)
mkdir -p "$QUARANTINE_DIR"

# ค้นหาไฟล์สำรองหรือไฟล์ซากชั่วคราวที่มีนามสกุล .bak, .tmp หรือลงท้ายด้วย ~
dup_count=0
find "$WORKSPACE" -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*~" \) | while read -r file; do
    if [[ -f "$file" ]]; then
        print "⚠️ [QUARANTINE] Moving redundant file: $(basename "$file")"
        mv "$file" "$QUARANTINE_DIR/"
        ((dup_count++))
    fi
done

print "✅ [HYGIENE COMPLETE] System audit finished. Quarantined items moved safely to:"
print "   📁 $QUARANTINE_DIR"
