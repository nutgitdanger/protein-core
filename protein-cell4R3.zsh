#!/usr/bin/env zsh

setopt NO_NOMATCH
setopt NULL_GLOB

BIN="/data/data/com.termux/files/usr/bin"
HOME_DIR="/data/data/com.termux/files/home"

R="$HOME_DIR/.config/dynu-audit/protein"
CELL3="$R/02-collector/checkpoints/cell3-molecule-20260905-020636"

RUN="$($BIN/date +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell4R3-dependency-$RUN"

MOL="$CELL3/molecules/molecules.tsv"
MEM="$CELL3/molecules/membership.tsv"
REL="$CELL3/relations/relations.tsv"
RES="$CELL3/input/resources.tsv"

mkdir -p \
"$OUT/01-input" \
"$OUT/02-mapping" \
"$OUT/03-relations" \
"$OUT/04-dependency" \
"$OUT/05-completeness" \
"$OUT/06-gaps" \
"$OUT/07-recovery" \
"$OUT/08-verification"

echo '============================================================'
echo ' PROTEIN V2 — CELL 4R3'
echo ' CORRECT SCHEMA / HASH-NAME BRIDGE'
echo '============================================================'
echo "RUN=$RUN"
echo "CELL3=$CELL3"
echo "OUTPUT=$OUT"
echo

# ============================================================
# SAFETY
# ============================================================

cat > "$OUT/01-input/safety.tsv" <<SAFE
MODE	CELL4R3_ANALYSIS_ONLY
SOURCE_MODIFY	NO
SOURCE_DELETE	NO
SOURCE_MOVE	NO
SOURCE_RENAME	NO
SOURCE_QUARANTINE	NO
DNA_MUTATION	NO
CREDENTIAL_READ	NO
EXTERNAL_WRITE	NO
RESOURCE_EXECUTE	NO
PROCESS_KILL	NO
AUTO_DELETE	false
AUTO_MOVE	false
AUTO_QUARANTINE	false
AUTO_KILL	false
RIGHTS	INHERITED_ONLY
SAFE

# ============================================================
# CORE 1 — INPUT
# ============================================================

echo '[CORE 1] INPUT / INTEGRITY'

for f in "$MOL" "$MEM" "$REL" "$RES"
do
    if [[ -f "$f" ]]; then
        echo "PASS $f"
    else
        echo "FAIL $f"
        exit 1
    fi
done

RES_COUNT=$($BIN/wc -l < "$RES")
MEM_COUNT=$($BIN/wc -l < "$MEM")
MOL_COUNT=$($BIN/wc -l < "$MOL")
REL_COUNT=$($BIN/wc -l < "$REL")

echo "RESOURCES=$RES_COUNT"
echo "MEMBERSHIP=$MEM_COUNT"
echo "MOLECULES=$MOL_COUNT"
echo "RELATIONS=$REL_COUNT"
echo

# ============================================================
# CORE 2 — RESOURCE → MOLECULE
#
# resources:
#   $1 = filename/hash
#
# membership:
#   $1 = molecule
#   $6 = filename/hash
# ============================================================

echo '[CORE 2] RESOURCE → MOLECULE'

$BIN/awk -F '\t' '
{
    molecule=$1
    key=$6

    if (molecule != "" && key != "")
        molecule_by_key[key]=molecule
}
END {
    for (key in molecule_by_key)
        print key "\t" molecule_by_key[key]
}
' "$MEM" |
$BIN/sort > "$OUT/02-mapping/key-to-molecule.tsv"

$BIN/awk -F '\t' '
NR==FNR {
    molecule_by_key[$1]=$2
    next
}
{
    key=$1

    if (key in molecule_by_key) {
        print molecule_by_key[key] "\t" $0
        mapped++
    } else {
        print $0
        unassigned++
    }
}
END {
    print mapped > "'"$OUT/02-mapping/.mapped"'"
    print unassigned > "'"$OUT/02-mapping/.unassigned"'"
}
' \
"$OUT/02-mapping/key-to-molecule.tsv" \
"$RES" \
> "$OUT/02-mapping/resource-map.raw"

MAPPED=$($BIN/cat "$OUT/02-mapping/.mapped")
UNASSIGNED=$($BIN/cat "$OUT/02-mapping/.unassigned")

# resource-map.raw contains mapped records only,
# because the second awk output is all records.
# Separate using key lookup again, without rescanning Cell 3.

$BIN/awk -F '\t' '
NR==FNR {
    map[$1]=$2
    next
}
{
    if ($1 in map)
        print map[$1] "\t" $0
    else
        print $0 > "'"$OUT/02-mapping/unassigned.tsv"'"
}
' \
"$OUT/02-mapping/key-to-molecule.tsv" \
"$RES" \
> "$OUT/02-mapping/resource-map.tsv"

MAPPED=$($BIN/wc -l < "$OUT/02-mapping/resource-map.tsv")
UNASSIGNED=$($BIN/wc -l < "$OUT/02-mapping/unassigned.tsv")

echo "RESOURCE_COUNT=$RES_COUNT"
echo "MEMBERSHIP_COUNT=$MEM_COUNT"
echo "MAPPED_RESOURCES=$MAPPED"
echo "UNASSIGNED_RESOURCES=$UNASSIGNED"
echo

# ============================================================
# CORE 3 — RELATION → MOLECULE
#
# relations:
#   $5 = filename/hash
# ============================================================

echo '[CORE 3] RELATION ANALYSIS'

: > "$OUT/03-relations/relation-map.tsv"
: > "$OUT/03-relations/cross.tsv"

$BIN/awk -F '\t' '
NR==FNR {
    map[$1]=$2
    next
}
{
    key=$5

    if (key in map) {
        molecule=map[key]

        print molecule "\t" $0

        if ($1 != $2)
            print molecule "\t" $1 "\t" $2 "\tCROSS" \
              > "'"$OUT/03-relations/cross.tsv"'"

        mapped++
    }
}
END {
    print mapped > "'"$OUT/03-relations/.mapped"'"
}
' \
"$OUT/02-mapping/key-to-molecule.tsv" \
"$REL" \
> "$OUT/03-relations/relation-map.tsv"

REL_MAPPED=$($BIN/wc -l < "$OUT/03-relations/relation-map.tsv")
REL_CROSS=$($BIN/wc -l < "$OUT/03-relations/cross.tsv")

echo "RELATIONS_INPUT=$REL_COUNT"
echo "RELATIONS_MAPPED=$REL_MAPPED"
echo "CROSS_RELATIONS=$REL_CROSS"
echo

# ============================================================
# CORE 4 — DEPENDENCY
# ============================================================

echo '[CORE 4] DEPENDENCY'

$BIN/awk -F '\t' '
NR==FNR {
    molecule[$1]=1
    next
}
{
    internal[$1]++
}
END {
    for (m in molecule) {
        if (cross[m] > 0)
            type="CROSS_DEPENDENCY"
        else if (internal[m] > 0)
            type="INTERNAL_DEPENDENCY"
        else
            type="NO_RELATION"

        print m "\t" (internal[m]+0) "\t" (cross[m]+0) "\t" type
    }
}
' \
"$MOL" \
"$OUT/03-relations/relation-map.tsv" \
> "$OUT/04-dependency/dependency.tsv"

# Add cross counts separately
$BIN/awk -F '\t' '
{
    cross[$1]++
}
END {
    for (m in cross)
        print m "\t" cross[m]
}
' "$OUT/03-relations/cross.tsv" \
> "$OUT/04-dependency/cross-count.tsv"

DEPENDENCY_COUNT=$($BIN/wc -l < "$OUT/04-dependency/dependency.tsv")

CROSS_DEPENDENCY=$(
$BIN/awk -F '\t' '
{
    if ($4=="CROSS_DEPENDENCY") c++
}
END {print c+0}
' "$OUT/04-dependency/dependency.tsv"
)

INTERNAL_DEPENDENCY=$(
$BIN/awk -F '\t' '
{
    if ($4=="INTERNAL_DEPENDENCY") c++
}
END {print c+0}
' "$OUT/04-dependency/dependency.tsv"
)

NO_RELATION=$(
$BIN/awk -F '\t' '
{
    if ($4=="NO_RELATION") c++
}
END {print c+0}
' "$OUT/04-dependency/dependency.tsv"
)

echo "DEPENDENCY_RECORDS=$DEPENDENCY_COUNT"
echo "CROSS_DEPENDENCY=$CROSS_DEPENDENCY"
echo "INTERNAL_DEPENDENCY=$INTERNAL_DEPENDENCY"
echo "NO_RELATION=$NO_RELATION"
echo

# ============================================================
# CORE 5 — COMPLETENESS
# ============================================================

echo '[CORE 5] COMPLETENESS'

$BIN/awk -F '\t' '
NR==FNR {
    mol[$1]=1
    next
}
{
    assigned[$1]++
}
END {
    for (m in mol) {
        a=assigned[m]+0

        if (a > 0)
            state="COMPLETE"
        else
            state="EMPTY"

        print m "\t" a "\t" state
    }
}
' \
"$MOL" \
"$OUT/02-mapping/resource-map.tsv" \
> "$OUT/05-completeness/completeness.tsv"

COMPLETE_COUNT=$(
$BIN/awk -F '\t' '$3=="COMPLETE"{c++} END{print c+0}' \
"$OUT/05-completeness/completeness.tsv"
)

EMPTY_COUNT=$(
$BIN/awk -F '\t' '$3=="EMPTY"{c++} END{print c+0}' \
"$OUT/05-completeness/completeness.tsv"
)

COMPLETENESS_COUNT=$(
$BIN/wc -l < "$OUT/05-completeness/completeness.tsv"
)

echo "COMPLETE=$COMPLETE_COUNT"
echo "PARTIAL=0"
echo "EMPTY=$EMPTY_COUNT"
echo "COMPLETENESS_RECORDS=$COMPLETENESS_COUNT"
echo

# ============================================================
# CORE 6 — GAPS
# ============================================================

echo '[CORE 6] GAP / ORPHAN'

UNASSIGNED_COUNT=$(
$BIN/wc -l < "$OUT/02-mapping/unassigned.tsv"
)

$BIN/awk -F '\t' '
{
    print $1
}
' "$OUT/02-mapping/unassigned.tsv" |
$BIN/sort |
$BIN/uniq -c |
$BIN/sort -nr \
> "$OUT/06-gaps/gap-types.tsv"

$BIN/cp \
"$OUT/02-mapping/unassigned.tsv" \
"$OUT/06-gaps/unassigned.tsv"

GAP_TYPES=$(
$BIN/wc -l < "$OUT/06-gaps/gap-types.tsv"
)

echo "UNASSIGNED_RESOURCES=$UNASSIGNED_COUNT"
echo "GAP_TYPES=$GAP_TYPES"
echo

# ============================================================
# CORE 7 — RECOVERY / INSTINCT
# ============================================================

echo '[CORE 7] RECOVERY / INSTINCT'

: > "$OUT/07-recovery/recovery.tsv"

while IFS=$'\t' read -r molecule_name assigned_count complete_state
do

    [[ -z "$molecule_name" ]] && continue

    relation_count=$(
    $BIN/awk -F '\t' -v m="$molecule_name" '
    $1==m {c++}
    END {print c+0}
    ' "$OUT/03-relations/relation-map.tsv"
    )

    if (( assigned_count == 0 )); then
        instinct="OBSERVE"
        reason="NO_RESOURCE_ASSIGNMENT"
    elif (( relation_count == 0 )); then
        instinct="DIVE"
        reason="NO_RELATION_EVIDENCE"
    else
        instinct="HOLD"
        reason="RELATION_PRESENT"
    fi

    print -r -- \
    "$molecule_name	$assigned_count	$relation_count	$complete_state	$instinct	$reason" \
    >> "$OUT/07-recovery/recovery.tsv"

done < "$OUT/05-completeness/completeness.tsv"

RECOVERY_COUNT=$(
$BIN/wc -l < "$OUT/07-recovery/recovery.tsv"
)

INSTINCT_DIVE=$(
$BIN/awk -F '\t' '$5=="DIVE"{c++} END{print c+0}' \
"$OUT/07-recovery/recovery.tsv"
)

INSTINCT_HOLD=$(
$BIN/awk -F '\t' '$5=="HOLD"{c++} END{print c+0}' \
"$OUT/07-recovery/recovery.tsv"
)

INSTINCT_OBSERVE=$(
$BIN/awk -F '\t' '$5=="OBSERVE"{c++} END{print c+0}' \
"$OUT/07-recovery/recovery.tsv"
)

echo "RECOVERY_RECORDS=$RECOVERY_COUNT"
echo "INSTINCT_DIVE=$INSTINCT_DIVE"
echo "INSTINCT_HOLD=$INSTINCT_HOLD"
echo "INSTINCT_OBSERVE=$INSTINCT_OBSERVE"
echo

# ============================================================
# CORE 8 — FINAL GATE
# ============================================================

echo '[CORE 8] VERIFICATION / GATE'

FAIL=0

[[ "$RES_COUNT" == "1000" ]] || FAIL=1
[[ "$MEM_COUNT" == "992" ]] || FAIL=1
[[ "$MOL_COUNT" == "4" ]] || FAIL=1
[[ "$REL_COUNT" == "1000" ]] || FAIL=1

[[ "$MAPPED" == "992" ]] || FAIL=1
[[ "$UNASSIGNED_COUNT" == "8" ]] || FAIL=1

[[ "$REL_MAPPED" == "992" ]] || FAIL=1
[[ "$DEPENDENCY_COUNT" == "4" ]] || FAIL=1
[[ "$COMPLETENESS_COUNT" == "4" ]] || FAIL=1
[[ "$RECOVERY_COUNT" == "4" ]] || FAIL=1

if (( FAIL == 0 )); then
    RESULT="CELL_4_PASS"
else
    RESULT="CELL_4_FAIL"
fi

cat > "$OUT/08-verification/result.tsv" <<EOF2
RESULT	$RESULT
RESOURCES	$RES_COUNT
MEMBERSHIP	$MEM_COUNT
MOLECULES	$MOL_COUNT
RELATIONS	$REL_COUNT
MAPPED_RESOURCES	$MAPPED
UNASSIGNED_RESOURCES	$UNASSIGNED_COUNT
RELATIONS_MAPPED	$REL_MAPPED
DEPENDENCY_RECORDS	$DEPENDENCY_COUNT
COMPLETENESS_RECORDS	$COMPLETENESS_COUNT
RECOVERY_RECORDS	$RECOVERY_COUNT
SOURCE_MODIFY	NO
SOURCE_DELETE	NO
SOURCE_MOVE	NO
SOURCE_RENAME	NO
SOURCE_QUARANTINE	NO
DNA_MUTATION	NO
RESOURCE_EXECUTE	NO
PROCESS_KILL	NO
DECAY	NO
DELETE	NO
REPLACE	NO
LINEAGE	PRESERVED
RIGHTS	INHERITED_ONLY
EOF2

cat > "$OUT/08-verification/lineage.tsv" <<EOF2
ROOT	DNA
PARENT	PROTEIN
GENERATION	CELL_4R3
SOURCE	CELL_3
SOURCE_CHECKPOINT	$CELL3
RESULT	$RESULT
RIGHTS	INHERITED_ONLY
DNA_MUTATION	NO
SOURCE_DATA_INTACT	YES
DECAY	NO
DELETE	NO
REPLACE	NO
EOF2

echo
cat "$OUT/08-verification/result.tsv"
echo
echo '============================================================'

if (( FAIL == 0 )); then
    echo 'CELL 4 COMPLETE'
    echo 'RESULT=CELL_4_PASS'
else
    echo 'CELL 4 INCOMPLETE'
    echo 'RESULT=CELL_4_FAIL'
fi

echo "CHECKPOINT=$OUT"
echo "SOURCE_DATA=INTACT"
echo "DNA=UNCHANGED"
echo "LINEAGE=PRESERVED"
echo '============================================================'
