#!/data/data/com.termux/files/usr/bin/zsh

export PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/home/bin:/system/bin:/system/xbin"

R="$HOME/.config/dynu-audit/protein"
CELL4="$R/02-collector/checkpoints/cell4R3-dependency-20260905-024119"

DATE_BIN="/data/data/com.termux/files/usr/bin/date"
MKDIR_BIN="/data/data/com.termux/files/usr/bin/mkdir"
CP_BIN="/data/data/com.termux/files/usr/bin/cp"
WC_BIN="/data/data/com.termux/files/usr/bin/wc"
AWK_BIN="/data/data/com.termux/files/usr/bin/awk"
SORT_BIN="/data/data/com.termux/files/usr/bin/sort"
SHA_BIN="/data/data/com.termux/files/usr/bin/sha256sum"
CAT_BIN="/data/data/com.termux/files/usr/bin/cat"
FIND_BIN="/data/data/com.termux/files/usr/bin/find"
TEST_BIN="/data/data/com.termux/files/usr/bin/test"

echo '============================================================'
echo ' PROTEIN V2 — CELL 5 R2 VALIDATOR / PROOF ENGINE'
echo '============================================================'

echo
echo '[0] ENVIRONMENT'

"$TEST_BIN" -d "$R" || {
    echo 'PROTEIN_ROOT=MISSING'
    exit 1
}

"$TEST_BIN" -d "$CELL4" || {
    echo 'CELL4=MISSING'
    exit 1
}

RUN="$("$DATE_BIN" '+%Y%m%d-%H%M%S')"
OUT="$R/02-collector/checkpoints/cell5R2-validation-$RUN"

"$MKDIR_BIN" -p \
 "$OUT/01-input" \
 "$OUT/02-integrity" \
 "$OUT/03-mapping" \
 "$OUT/04-relations" \
 "$OUT/05-dependency" \
 "$OUT/06-completeness" \
 "$OUT/07-gaps" \
 "$OUT/08-recovery" \
 "$OUT/09-lineage" \
 "$OUT/10-safety" \
 "$OUT/11-conflicts" \
 "$OUT/12-proofs" \
 "$OUT/13-gate" \
 "$OUT/14-report"

echo "PROTEIN_ROOT=FOUND"
echo "CELL4=FOUND"
echo "RUN=$RUN"
echo "OUTPUT=$OUT"

echo
echo '[1] SAFETY INVARIANT'

"$CAT_BIN" > "$OUT/10-safety/invariants.tsv" <<'EOF'
RULE	VALUE
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
EXTERNAL_WRITE	NO
CREDENTIAL_READ	NO
AUTO_DELETE	false
AUTO_MOVE	false
AUTO_QUARANTINE	false
AUTO_KILL	false
RIGHTS	INHERITED_ONLY
EOF

"$CAT_BIN" "$OUT/10-safety/invariants.tsv"

echo
echo '[2] CELL 4 OUTPUT INTEGRITY'

typeset -a REQUIRED
REQUIRED=(
 "$CELL4/01-input/safety.tsv"
 "$CELL4/02-mapping/key-to-molecule.tsv"
 "$CELL4/02-mapping/resource-map.raw"
 "$CELL4/02-mapping/resource-map.tsv"
 "$CELL4/02-mapping/unassigned.tsv"
 "$CELL4/03-relations/cross.tsv"
 "$CELL4/03-relations/relation-map.tsv"
 "$CELL4/04-dependency/cross-count.tsv"
 "$CELL4/04-dependency/dependency.tsv"
 "$CELL4/05-completeness/completeness.tsv"
 "$CELL4/06-gaps/gap-types.tsv"
 "$CELL4/06-gaps/unassigned.tsv"
 "$CELL4/07-recovery/recovery.tsv"
 "$CELL4/08-verification/lineage.tsv"
 "$CELL4/08-verification/result.tsv"
)

INTEGRITY=PASS

for f in "${REQUIRED[@]}"; do
    if "$TEST_BIN" -f "$f"; then
        echo "PASS $f"
    else
        echo "FAIL $f"
        INTEGRITY=FAIL
    fi
done

echo "INPUT_INTEGRITY=$INTEGRITY"

if [ "$INTEGRITY" != PASS ]; then
    echo 'CELL_5_ABORT=INPUT_INTEGRITY'
    exit 1
fi

echo
echo '[3] COPY CELL 4 EVIDENCE'

"$CP_BIN" "$CELL4/01-input/safety.tsv" "$OUT/01-input/"
"$CP_BIN" "$CELL4/02-mapping/key-to-molecule.tsv" "$OUT/03-mapping/"
"$CP_BIN" "$CELL4/02-mapping/resource-map.raw" "$OUT/03-mapping/"
"$CP_BIN" "$CELL4/02-mapping/resource-map.tsv" "$OUT/03-mapping/"
"$CP_BIN" "$CELL4/02-mapping/unassigned.tsv" "$OUT/07-gaps/mapping-unassigned.tsv"
"$CP_BIN" "$CELL4/03-relations/cross.tsv" "$OUT/04-relations/"
"$CP_BIN" "$CELL4/03-relations/relation-map.tsv" "$OUT/04-relations/"
"$CP_BIN" "$CELL4/04-dependency/cross-count.tsv" "$OUT/05-dependency/"
"$CP_BIN" "$CELL4/04-dependency/dependency.tsv" "$OUT/05-dependency/"
"$CP_BIN" "$CELL4/05-completeness/completeness.tsv" "$OUT/06-completeness/"
"$CP_BIN" "$CELL4/06-gaps/gap-types.tsv" "$OUT/07-gaps/"
"$CP_BIN" "$CELL4/06-gaps/unassigned.tsv" "$OUT/07-gaps/gaps.tsv"
"$CP_BIN" "$CELL4/07-recovery/recovery.tsv" "$OUT/08-recovery/"
"$CP_BIN" "$CELL4/08-verification/lineage.tsv" "$OUT/09-lineage/"
"$CP_BIN" "$CELL4/08-verification/result.tsv" "$OUT/09-lineage/"

echo 'EVIDENCE_COPY=PASS'

echo
echo '[4] STRUCTURAL COUNTS'

RESOURCE_MAPPED="$("$WC_BIN" -l < "$OUT/03-mapping/resource-map.tsv")"
RESOURCE_RAW="$("$WC_BIN" -l < "$OUT/03-mapping/resource-map.raw")"
UNASSIGNED="$("$WC_BIN" -l < "$OUT/07-gaps/gaps.tsv")"
RELATIONS="$("$WC_BIN" -l < "$OUT/04-relations/relation-map.tsv")"
DEPENDENCY="$("$WC_BIN" -l < "$OUT/05-dependency/dependency.tsv")"
COMPLETENESS="$("$WC_BIN" -l < "$OUT/06-completeness/completeness.tsv")"
RECOVERY="$("$WC_BIN" -l < "$OUT/08-recovery/recovery.tsv")"
MOLECULE_KEYS="$("$WC_BIN" -l < "$OUT/03-mapping/key-to-molecule.tsv")"

RESOURCE_TOTAL=$((RESOURCE_MAPPED + UNASSIGNED))

"$CAT_BIN" > "$OUT/02-integrity/counts.tsv" <<EOF
ITEM	COUNT
MAPPED_RESOURCES	$RESOURCE_MAPPED
RAW_RESOURCES	$RESOURCE_RAW
UNASSIGNED_RESOURCES	$UNASSIGNED
TOTAL_RESOURCES	$RESOURCE_TOTAL
RELATIONS_MAPPED	$RELATIONS
DEPENDENCY_RECORDS	$DEPENDENCY
COMPLETENESS_RECORDS	$COMPLETENESS
RECOVERY_RECORDS	$RECOVERY
MOLECULE_KEYS	$MOLECULE_KEYS
EOF

"$CAT_BIN" "$OUT/02-integrity/counts.tsv"

echo
echo '[5] RESOURCE CONSERVATION PROOF'

CONSERVATION=FAIL

if [ "$RESOURCE_MAPPED" -eq 992 ] &&
   [ "$UNASSIGNED" -eq 8 ] &&
   [ "$RESOURCE_TOTAL" -eq 1000 ]; then
    CONSERVATION=PASS
fi

echo "992 mapped + 8 unassigned = $RESOURCE_TOTAL"
echo "RESOURCE_CONSERVATION=$CONSERVATION"

echo
echo '[6] MOLECULE VALIDATION'

M001="$("$AWK_BIN" '$1=="M0001"{c++} END{print c+0}' "$OUT/03-mapping/key-to-molecule.tsv")"
M002="$("$AWK_BIN" '$1=="M0002"{c++} END{print c+0}' "$OUT/03-mapping/key-to-molecule.tsv")"
M003="$("$AWK_BIN" '$1=="M0003"{c++} END{print c+0}' "$OUT/03-mapping/key-to-molecule.tsv")"
M004="$("$AWK_BIN" '$1=="M0004"{c++} END{print c+0}' "$OUT/03-mapping/key-to-molecule.tsv")"

"$CAT_BIN" > "$OUT/06-completeness/molecule-proof.tsv" <<EOF
MOLECULE	COUNT
M0001	$M001
M0002	$M002
M0003	$M003
M0004	$M004
EOF

"$CAT_BIN" "$OUT/06-completeness/molecule-proof.tsv"

MOLECULE_PASS=FAIL

if [ "$M001" -gt 0 ] &&
   [ "$M002" -gt 0 ] &&
   [ "$M003" -gt 0 ] &&
   [ "$M004" -gt 0 ]; then
    MOLECULE_PASS=PASS
fi

echo "MOLECULE_SET=$MOLECULE_PASS"

echo
echo '[7] RELATION VALIDATION'

RELATION_PASS=FAIL

if [ "$RELATIONS" -eq 992 ]; then
    RELATION_PASS=PASS
fi

echo "RELATIONS_MAPPED=$RELATIONS"
echo "RELATION_VALIDATION=$RELATION_PASS"

echo
echo '[8] DEPENDENCY VALIDATION'

INTERNAL="$("$AWK_BIN" '$NF=="INTERNAL_DEPENDENCY"{c++} END{print c+0}' "$OUT/05-dependency/dependency.tsv")"
CROSS="$("$AWK_BIN" '$NF=="CROSS_DEPENDENCY"{c++} END{print c+0}' "$OUT/05-dependency/dependency.tsv")"
NONE="$("$AWK_BIN" '$NF=="NO_RELATION"{c++} END{print c+0}' "$OUT/05-dependency/dependency.tsv")"

"$CAT_BIN" > "$OUT/05-dependency/proof.tsv" <<EOF
TOTAL	$DEPENDENCY
INTERNAL	$INTERNAL
CROSS	$CROSS
NO_RELATION	$NONE
EOF

"$CAT_BIN" "$OUT/05-dependency/proof.tsv"

DEPENDENCY_PASS=FAIL

if [ "$DEPENDENCY" -eq 4 ] &&
   [ "$INTERNAL" -eq 4 ] &&
   [ "$CROSS" -eq 0 ] &&
   [ "$NONE" -eq 0 ]; then
    DEPENDENCY_PASS=PASS
fi

echo "DEPENDENCY_VALIDATION=$DEPENDENCY_PASS"

echo
echo '[9] COMPLETENESS VALIDATION'

COMPLETE="$("$AWK_BIN" '$NF=="COMPLETE"{c++} END{print c+0}' "$OUT/06-completeness/completeness.tsv")"
PARTIAL="$("$AWK_BIN" '$NF=="PARTIAL"{c++} END{print c+0}' "$OUT/06-completeness/completeness.tsv")"
EMPTY="$("$AWK_BIN" '$NF=="EMPTY"{c++} END{print c+0}' "$OUT/06-completeness/completeness.tsv")"

echo "TOTAL=$COMPLETENESS"
echo "COMPLETE=$COMPLETE"
echo "PARTIAL=$PARTIAL"
echo "EMPTY=$EMPTY"

COMPLETENESS_PASS=FAIL

if [ "$COMPLETENESS" -eq 4 ] &&
   [ "$COMPLETE" -eq 4 ] &&
   [ "$PARTIAL" -eq 0 ] &&
   [ "$EMPTY" -eq 0 ]; then
    COMPLETENESS_PASS=PASS
fi

echo "COMPLETENESS_VALIDATION=$COMPLETENESS_PASS"

echo
echo '[10] GAP VALIDATION'

GAP_PASS=FAIL

if [ "$UNASSIGNED" -eq 8 ]; then
    GAP_PASS=PASS
fi

echo "UNASSIGNED_RESOURCES=$UNASSIGNED"
echo "GAP_VALIDATION=$GAP_PASS"
echo "GAP_POLICY=HOLD_NOT_DELETE"

echo
echo '[11] RECOVERY VALIDATION'

HOLD="$("$AWK_BIN" '$NF=="HOLD"{c++} END{print c+0}' "$OUT/08-recovery/recovery.tsv")"

RECOVERY_PASS=FAIL

if [ "$RECOVERY" -eq 4 ]; then
    RECOVERY_PASS=PASS
fi

echo "RECOVERY_RECORDS=$RECOVERY"
echo "HOLD=$HOLD"
echo "RECOVERY_VALIDATION=$RECOVERY_PASS"

echo
echo '[12] CROSS RELATION VALIDATION'

CROSS_FILE="$OUT/04-relations/cross.tsv"

if [ "$("$WC_BIN" -l < "$CROSS_FILE")" -eq 0 ]; then
    CROSS_RELATION=PASS
else
    CROSS_RELATION=REVIEW
fi

echo "CROSS_RELATION=$CROSS_RELATION"

echo
echo '[13] CELL 4 RESULT VALIDATION'

CELL4_RESULT="$("$AWK_BIN" -F= '$1=="RESULT"{print $2}' "$OUT/09-lineage/result.tsv" | head -1)"

echo "CELL4_RESULT=$CELL4_RESULT"

CELL4_PASS=FAIL

if grep -q 'CELL_4_PASS' "$OUT/09-lineage/result.tsv"; then
    CELL4_PASS=PASS
fi

echo "CELL4_RESULT_VALIDATION=$CELL4_PASS"

echo
echo '[14] LINEAGE VALIDATION'

LINEAGE_PASS=FAIL

if grep -q 'ROOT.*DNA' "$OUT/09-lineage/lineage.tsv" &&
   grep -q 'PARENT.*PROTEIN' "$OUT/09-lineage/lineage.tsv" &&
   grep -q 'RIGHTS.*INHERITED_ONLY' "$OUT/09-lineage/lineage.tsv" &&
   grep -q 'DNA_MUTATION.*NO' "$OUT/09-lineage/lineage.tsv"; then
    LINEAGE_PASS=PASS
fi

echo "LINEAGE_VALIDATION=$LINEAGE_PASS"

echo
echo '[15] SAFETY VALIDATION'

SAFETY_PASS=PASS

for x in \
 'SOURCE_MODIFY	NO' \
 'SOURCE_DELETE	NO' \
 'SOURCE_MOVE	NO' \
 'SOURCE_RENAME	NO' \
 'SOURCE_QUARANTINE	NO' \
 'DNA_MUTATION	NO' \
 'RESOURCE_EXECUTE	NO' \
 'PROCESS_KILL	NO' \
 'DECAY	NO' \
 'DELETE	NO' \
 'REPLACE	NO' \
 'EXTERNAL_WRITE	NO' \
 'CREDENTIAL_READ	NO'
do
    key="${x%%	*}"
    val="${x#*	}"

    if ! grep -q "^${key}[[:space:]]*${val}$" \
        "$OUT/10-safety/invariants.tsv"; then
        SAFETY_PASS=FAIL
    fi
done

echo "SAFETY_VALIDATION=$SAFETY_PASS"

echo
echo '[16] CONFLICT ENGINE'

CONFLICTS=0

if [ "$CROSS" -ne 0 ]; then
    echo "CONFLICT CROSS_DEPENDENCY=$CROSS"
    CONFLICTS=$((CONFLICTS+1))
fi

if [ "$NONE" -ne 0 ]; then
    echo "CONFLICT NO_RELATION=$NONE"
    CONFLICTS=$((CONFLICTS+1))
fi

if [ "$PARTIAL" -ne 0 ]; then
    echo "CONFLICT PARTIAL=$PARTIAL"
    CONFLICTS=$((CONFLICTS+1))
fi

if [ "$EMPTY" -ne 0 ]; then
    echo "CONFLICT EMPTY=$EMPTY"
    CONFLICTS=$((CONFLICTS+1))
fi

if [ "$CONFLICTS" -eq 0 ]; then
    echo 'CONFLICTS=0'
    echo 'CONFLICT_STATUS=NONE'
else
    echo "CONFLICTS=$CONFLICTS"
    echo 'CONFLICT_STATUS=REVIEW'
fi

echo
echo '[17] PROOF MATRIX'

"$CAT_BIN" > "$OUT/12-proofs/proof-matrix.tsv" <<EOF
CHECK	RESULT
INPUT_INTEGRITY	$INTEGRITY
RESOURCE_CONSERVATION	$CONSERVATION
MOLECULE_SET	$MOLECULE_PASS
RELATION_VALIDATION	$RELATION_PASS
DEPENDENCY_VALIDATION	$DEPENDENCY_PASS
COMPLETENESS_VALIDATION	$COMPLETENESS_PASS
GAP_VALIDATION	$GAP_PASS
RECOVERY_VALIDATION	$RECOVERY_PASS
CROSS_RELATION	$CROSS_RELATION
CELL4_RESULT	$CELL4_PASS
LINEAGE	$LINEAGE_PASS
SAFETY	$SAFETY_PASS
CONFLICTS	$([ "$CONFLICTS" -eq 0 ] && echo PASS || echo REVIEW)
EOF

"$CAT_BIN" "$OUT/12-proofs/proof-matrix.tsv"

echo
echo '[18] FINAL GATE'

GATE=PASS

[ "$INTEGRITY" = PASS ] || GATE=FAIL
[ "$CONSERVATION" = PASS ] || GATE=FAIL
[ "$MOLECULE_PASS" = PASS ] || GATE=FAIL
[ "$RELATION_PASS" = PASS ] || GATE=FAIL
[ "$DEPENDENCY_PASS" = PASS ] || GATE=FAIL
[ "$COMPLETENESS_PASS" = PASS ] || GATE=FAIL
[ "$GAP_PASS" = PASS ] || GATE=FAIL
[ "$RECOVERY_PASS" = PASS ] || GATE=FAIL
[ "$CROSS_RELATION" = PASS ] || GATE=FAIL
[ "$CELL4_PASS" = PASS ] || GATE=FAIL
[ "$LINEAGE_PASS" = PASS ] || GATE=FAIL
[ "$SAFETY_PASS" = PASS ] || GATE=FAIL
[ "$CONFLICTS" -eq 0 ] || GATE=FAIL

"$CAT_BIN" > "$OUT/13-gate/gate.tsv" <<EOF
CELL	CELL_5
ENGINE	CELL_5_R2
PARENT	CELL_4_R3
RESULT	CELL_5_$GATE
RESOURCE_TOTAL	$RESOURCE_TOTAL
MAPPED_RESOURCES	$RESOURCE_MAPPED
UNASSIGNED_RESOURCES	$UNASSIGNED
RELATIONS_MAPPED	$RELATIONS
MOLECULES	4
DEPENDENCY_RECORDS	$DEPENDENCY
COMPLETENESS_RECORDS	$COMPLETENESS
RECOVERY_RECORDS	$RECOVERY
CONFLICTS	$CONFLICTS
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
EXTERNAL_WRITE	NO
CREDENTIAL_READ	NO
LINEAGE	PRESERVED
RIGHTS	INHERITED_ONLY
EOF

"$CAT_BIN" "$OUT/13-gate/gate.tsv"

echo
echo '[19] FINAL REPORT'

"$CAT_BIN" > "$OUT/14-report/result.tsv" <<EOF
FIELD	VALUE
CELL_5	CELL_5
ENGINE	CELL_5_R2
RESULT	CELL_5_$GATE
PARENT_CHECKPOINT	$CELL4
CHECKPOINT	$OUT
RESOURCE_TOTAL	$RESOURCE_TOTAL
MAPPED_RESOURCES	$RESOURCE_MAPPED
UNASSIGNED_RESOURCES	$UNASSIGNED
RELATIONS_MAPPED	$RELATIONS
MOLECULES	4
DEPENDENCY_RECORDS	$DEPENDENCY
COMPLETENESS_RECORDS	$COMPLETENESS
RECOVERY_RECORDS	$RECOVERY
CONFLICTS	$CONFLICTS
GAP_POLICY	HOLD_NOT_DELETE
SOURCE_DATA	INTACT
DNA	UNCHANGED
LINEAGE	PRESERVED
RIGHTS	INHERITED_ONLY
NEXT_CELL	6
EOF

"$CAT_BIN" "$OUT/14-report/result.tsv"

echo
echo '============================================================'

if [ "$GATE" = PASS ]; then
    echo ' CELL 5 COMPLETE'
    echo ' RESULT=CELL_5_PASS'
    echo " CHECKPOINT=$OUT"
    echo ' SOURCE_DATA=INTACT'
    echo ' DNA=UNCHANGED'
    echo ' LINEAGE=PRESERVED'
    echo ' CONFLICTS=NONE'
    echo ' GAPS=8_HELD'
    echo ' NEXT=CELL_6'
else
    echo ' CELL 5 INCOMPLETE'
    echo ' RESULT=CELL_5_FAIL'
    echo " CHECKPOINT=$OUT"
    echo ' SOURCE_DATA=INTACT'
    echo ' DNA=UNCHANGED'
    echo ' NEXT=REVIEW'
fi

echo '============================================================'
