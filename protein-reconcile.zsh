#!/data/data/com.termux/files/usr/bin/zsh

setopt NO_NOMATCH

A="$HOME/protein"
B="$HOME/.config/dynu-audit/protein"

echo "============================================================"
echo " PROTEIN RECONCILIATION AUDIT — READ ONLY"
echo "============================================================"

echo
echo "[1] ROOTS"
echo "CORE_ROOT=$A"
echo "AUDIT_ROOT=$B"

for R in "$A" "$B"; do
    echo
    echo "ROOT=$R"

    if [[ -d "$R" ]]; then
        echo "EXISTS=YES"
        echo "SIZE=$(du -sh "$R" 2>/dev/null | awk '{print $1}')"
        echo "FILES=$(find "$R" -type f 2>/dev/null | wc -l)"
        echo "DIRS=$(find "$R" -type d 2>/dev/null | wc -l)"
    else
        echo "EXISTS=NO"
    fi
done

echo
echo "[2] TOP LEVEL — CORE"
find "$A" -mindepth 1 -maxdepth 1 -type d \
    -printf '%f\n' 2>/dev/null | sort

echo
echo "[3] TOP LEVEL — AUDIT"
find "$B" -mindepth 1 -maxdepth 1 -type d \
    -printf '%f\n' 2>/dev/null | sort

echo
echo "[4] COMMON DIRECTORY NAMES"
comm -12 \
    <(find "$A" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort) \
    <(find "$B" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

echo
echo "[5] CORE SCHEMA"
if [[ -f "$A/00-core/schema/state/model.txt" ]]; then
    cat "$A/00-core/schema/state/model.txt"
else
    echo "SCHEMA=NOT_FOUND"
fi

echo
echo "[6] OBSERVER FILES — CORE"
find "$A/01-observer" -type f -maxdepth 2 \
    -printf '%P\n' 2>/dev/null | sort

echo
echo "[7] OBSERVER FILES — AUDIT"
find "$B/01-observer" -type f -maxdepth 2 \
    -printf '%P\n' 2>/dev/null | sort

echo
echo "[8] POSSIBLE SAME-NAME RESOURCES"
comm -12 \
    <(find "$A" -type f -printf '%f\n' 2>/dev/null | sort -u) \
    <(find "$B" -type f -printf '%f\n' 2>/dev/null | sort -u) |
head -100

echo
echo "[9] SYMLINKS — CORE"
find "$A" -type l -printf '%P -> %l\n' 2>/dev/null

echo
echo "[10] SYMLINKS — AUDIT"
find "$B" -type l -printf '%P -> %l\n' 2>/dev/null

echo
echo "[11] LARGE FILES >10MB"
find "$A" "$B" -type f -size +10M \
    -printf '%s %p\n' 2>/dev/null |
sort -nr |
head -30

echo
echo "[12] TEMP / PARTIAL"
find "$A" "$B" -type f \
    \( -name '*.tmp' -o -name '*.partial' -o -name '*.part' -o -name '*~' \) \
    -print 2>/dev/null

echo
echo "[13] GIT"
for R in "$A" "$B"; do
    if [[ -d "$R/.git" ]]; then
        echo "GIT=$R"
    else
        echo "NO_GIT=$R"
    fi
done

echo
echo "============================================================"
echo " AUDIT COMPLETE — NOTHING CHANGED"
echo "============================================================"
