#!/usr/bin/env zsh

ROOT="$HOME/.config/dynu-audit"
BEAD="$ROOT/protein/11-molecules/beads"
STAMP="$(date +%Y%m%d_%H%M%S)"

RAW="$BEAD/symlink-axis.$STAMP.raw"
AXIS="$BEAD/symlink-axis.$STAMP.state"
LATEST="$BEAD/symlink-axis.latest"

mkdir -p "$BEAD"

: > "$RAW"

find "$ROOT" -type l -print0 2>/dev/null |
while IFS= read -r -d '' LINK; do
    TARGET="$(readlink -f "$LINK" 2>/dev/null)"
    [ -n "$TARGET" ] || TARGET="$(readlink "$LINK" 2>/dev/null)"
    printf '%s\t%s\n' "$LINK" "$TARGET" >> "$RAW"
done

{
    echo "TYPE=SYMLINK_RELATION_BEAD_AXIS"
    echo "STATUS=CAPTURED"
    echo "TIMESTAMP=$STAMP"
    echo "ROOT=$ROOT"
    echo "SOURCE=$RAW"
    echo "RELATIONS=$(wc -l < "$RAW" | tr -d ' ')"
    echo "TARGET_GROUPS=$(cut -f2 "$RAW" | sort -u | wc -l | tr -d ' ')"
    echo "AXIS=TARGET_CONVERGENCE"
    echo "MODE=OBSERVE_AND_GROUP"
    echo
    echo "=== HIGH-CONVERGENCE TARGETS ==="
    cut -f2 "$RAW" |
        sort |
        uniq -c |
        sort -nr |
        head -30 |
        awk '{count=$1; $1=""; sub(/^ /,""); print count "\t" $0}'
} > "$AXIS"

ln -sfn "$AXIS" "$LATEST"

echo "=== SYMLINK BEAD AXIS ==="
grep -E '^(STATUS|RELATIONS|TARGET_GROUPS|AXIS|MODE)=' "$AXIS"
echo
echo "=== TOP TARGETS ==="
sed -n '/=== HIGH-CONVERGENCE TARGETS ===/,$p' "$AXIS"
echo
echo "SAVED=$AXIS"
echo "LATEST=$LATEST"
