#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/.config/dynu-audit"
OUT="$ROOT/runs/$(date +%Y%m%d_%H%M%S)-project-map"
mkdir -p "$OUT"

LOG="$OUT/project-map.log"
exec > >(tee "$LOG") 2>&1

echo "============================================================"
echo "NUT DYNU PROJECT MAP — READ ONLY"
echo "============================================================"
echo "DATE=$(date -Is)"
echo "HOME=$HOME"
echo "DYNU_ROOT=$ROOT"
echo

echo "===== 1. ENVIRONMENT ====="
printf 'SHELL=%s\n' "${SHELL:-}"
printf 'PREFIX=%s\n' "${PREFIX:-}"
printf 'USER=%s\n' "$(id -un)"
uname -a
echo

echo "===== 2. ROOT DIRECTORIES ====="
find "$HOME" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort
echo

echo "===== 3. DYNU ROOT ====="
if [[ -d "$ROOT" ]]; then
    echo "DYNU_ROOT=EXISTS"
    printf 'FILES=%s\n' "$(find "$ROOT" -type f 2>/dev/null | wc -l)"
    printf 'DIRS=%s\n' "$(find "$ROOT" -type d 2>/dev/null | wc -l)"
    printf 'LINKS=%s\n' "$(find "$ROOT" -type l 2>/dev/null | wc -l)"
else
    echo "DYNU_ROOT=MISSING"
fi
echo

echo "===== 4. DIRECT DYNU FILES ====="
find "$ROOT" -maxdepth 2 -type f -printf '%p\n' 2>/dev/null | sort
echo

echo "===== 5. EXECUTION-PATH CANDIDATES ====="
for f in \
    "$HOME/dynu_update.sh" \
    "$ROOT/dynu-api.sh" \
    "$ROOT/dynu-audit.sh" \
    "$ROOT/dns_inventory.sh" \
    "$ROOT/dns-capability-audit.sh" \
    "$ROOT/build-dns-capability-state.sh" \
    "$ROOT/dynu-controller.sh" \
    "$ROOT/dynamic-dynu-engine.sh"
do
    if [[ -f "$f" ]]; then
        printf 'EXISTS\t%s\n' "$f"
    else
        printf 'MISSING\t%s\n' "$f"
    fi
done
echo

echo "===== 6. ALL DYNU-RELATED SHELL FILES ====="
find "$HOME" -type f \
    \( -name '*dynu*.sh' -o -name '*dns*.sh' -o -name '*network*source*.sh' \) \
    -printf '%p\n' 2>/dev/null | sort
echo

echo "===== 7. CRON / SCHEDULE REFERENCES ====="
{
    crontab -l 2>/dev/null || true
    find "$HOME/.config" "$HOME/.termux" "$HOME" \
        -maxdepth 4 -type f \
        \( -name 'crontab' -o -name '*.cron' -o -name '*schedule*' \) \
        -print 2>/dev/null
} | grep -Ei 'dynu|dns|update|engine|controller|5[[:space:]]*\*' || true
echo

echo "===== 8. SOURCE REFERENCES ====="
grep -RInE \
    --exclude='*.log' \
    --exclude='*.json' \
    --exclude-dir=runs \
    --exclude-dir=raw \
    --exclude-dir=.git \
    'dynu_update|dynu-api|dynamic-dynu-engine|dynu-controller|DYNU_API_URL|DYNU_API_KEY|13248403|13248427|13248431|13248473|curl.*api\.dynu\.com' \
    "$HOME" 2>/dev/null | head -500
echo

echo "===== 9. MUTATION REFERENCES ====="
grep -RInE \
    --exclude='*.log' \
    --exclude='*.json' \
    --exclude-dir=runs \
    --exclude-dir=raw \
    --exclude-dir=.git \
    'curl.*(-X[[:space:]]*)?(POST|PUT|PATCH|DELETE)|-X[[:space:]]*(POST|PUT|PATCH|DELETE)|POST=|REAL_POST|MUTATION|mutation' \
    "$ROOT" 2>/dev/null | head -500
echo

echo "===== 10. READ/WRITE STATE REFERENCES ====="
grep -RInE \
    --exclude='*.log' \
    --exclude='*.json' \
    --exclude-dir=runs \
    --exclude-dir=raw \
    'state/|current\.env|latest-capability|latest|\.env|\.last_ip|printf.*state|echo.*state' \
    "$ROOT" 2>/dev/null | head -500
echo

echo "===== 11. DEPENDENCY COMMANDS ====="
for c in bash zsh curl jq ssh ip ping getprop crontab sha256sum find grep awk sed; do
    if command -v "$c" >/dev/null 2>&1; then
        printf 'OK\t%s\t%s\n' "$c" "$(command -v "$c")"
    else
        printf 'MISSING\t%s\n' "$c"
    fi
done
echo

echo "===== 12. SYNTAX CHECK — SHELL FILES ONLY ====="
find "$ROOT" -type f -name '*.sh' -print0 2>/dev/null |
while IFS= read -r -d '' f; do
    if bash -n "$f" >/dev/null 2>&1; then
        printf 'SYNTAX_OK\t%s\n' "$f"
    else
        printf 'SYNTAX_FAIL\t%s\n' "$f"
    fi
done
echo

echo "===== 13. PERMISSION / EXECUTABLE CHECK ====="
find "$ROOT" -type f -name '*.sh' -printf '%M\t%p\n' 2>/dev/null | sort
echo

echo "===== 14. LATEST RUNS ====="
find "$ROOT/runs" -mindepth 1 -maxdepth 1 -type d \
    -printf '%T@ %p\n' 2>/dev/null |
sort -nr | head -20
echo

echo "===== 15. RECENT EVIDENCE ====="
find "$ROOT/runs" -type f \
    -printf '%T@ %p\n' 2>/dev/null |
sort -nr | head -30
echo

echo "===== 16. FILE COUNTS ====="
printf 'DYNU_SH=%s\n' "$(find "$HOME" -type f -name '*dynu*.sh' 2>/dev/null | wc -l)"
printf 'DNS_SH=%s\n' "$(find "$HOME" -type f -name '*dns*.sh' 2>/dev/null | wc -l)"
printf 'RUN_DIRS=%s\n' "$(find "$ROOT/runs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
printf 'RAW_FILES=%s\n' "$(find "$ROOT/raw" -type f 2>/dev/null | wc -l)"
printf 'STATE_FILES=%s\n' "$(find "$ROOT/state" -type f 2>/dev/null | wc -l)"
echo

echo "============================================================"
echo "MAP COMPLETE"
echo "LOG=$LOG"
echo "NO POST"
echo "NO PUT"
echo "NO PATCH"
echo "NO DELETE"
echo "============================================================"
