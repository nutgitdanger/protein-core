#!/usr/bin/env zsh

ROOT="$HOME/.config/dynu-audit"
BEAD="$ROOT/protein/11-molecules/beads"
AXIS="$BEAD/symlink-axis.latest"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$BEAD/bead-axis.$STAMP.state"

[ -f "$AXIS" ] || { echo "ERROR=SYMLINK_AXIS_NOT_FOUND"; exit 1; }

RAW="$(sed -n 's/^SOURCE=//p' "$AXIS" | head -1)"
[ -f "$RAW" ] || { echo "ERROR=RAW_RELATION_SOURCE_NOT_FOUND"; exit 1; }

{
    echo "TYPE=BEAD_RELATION_AXIS"
    echo "STATUS=EXTENDED"
    echo "TIMESTAMP=$STAMP"
    echo "ROOT=$ROOT"
    echo "SOURCE_AXIS=$AXIS"
    echo "SOURCE_RAW=$RAW"
    echo "MODE=APPEND_PRESERVE"
    echo "AXIS=EXISTING_BEAD"
    echo "RELATION_KEY=SYMLINK_TARGET"
    echo "ORDER=EXISTING_BEAD_FIRST"
    echo
    echo "=== EXISTING BEAD AXIS ==="

    find "$BEAD" -maxdepth 1 -type f -name 'bead-*.state' -print |
    sort -V |
    while IFS= read -r f; do
        name="${f:t}"
        id="${name#bead-}"
        id="${id%.state}"
        printf 'AXIS_BEAD=%s\tFILE=%s\n' "$id" "$f"
    done

    echo
    echo "=== SYMLINK → EXISTING AXIS ==="

    awk -F '\t' '
    NF >= 2 {
        target=$2
        count[target]++
        links[target]=links[target] "\n  " $1
    }
    END {
        for (target in count) {
            print "TARGET_COUNT=" count[target]
            print "AXIS_TARGET=" target
            print "POINTS_TO=EXISTING_AXIS"
            printf "%s", links[target]
            print "\n"
        }
    }
    ' "$RAW" | sort -n -r
} > "$OUT"

ln -sfn "$OUT" "$BEAD/bead-axis.latest"

echo "=== BEAD AXIS ==="
grep -E '^(TYPE|STATUS|MODE|AXIS|RELATION_KEY|ORDER)=' "$OUT"
echo
echo "=== SYMLINK → AXIS ==="
grep -E '^(TARGET_COUNT|AXIS_TARGET|POINTS_TO=)' "$OUT" | head -30
echo
echo "SAVED=$OUT"
echo "LATEST=$BEAD/bead-axis.latest"
