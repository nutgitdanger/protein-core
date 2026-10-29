#!/data/data/com.termux/files/usr/bin/zsh

BIN="/data/data/com.termux/files/usr/bin"
export PATH="$BIN:$HOME/bin:/system/bin:/system/xbin"

R="$HOME/.config/dynu-audit/protein"

C4="$R/02-collector/checkpoints/cell4R3-dependency-20260905-024119"
C5="$R/02-collector/checkpoints/cell5R3-validation-20260905-025128"
C6="$R/02-collector/checkpoints/cell6R1-gap-20260905-025357"
C7="$R/02-collector/checkpoints/cell7R1-correlation-20260905-025525"

RUN="$("$BIN/date" +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell8R3-deep-$RUN"

"$BIN/mkdir" -p \
  "$OUT/01-input" \
  "$OUT/02-inspection" \
  "$OUT/03-evidence" \
  "$OUT/04-decisions" \
  "$OUT/05-verification"

FAIL=0

echo '============================================================'
echo ' PROTEIN — CELL 8 R3 — TARGETED DEEP INSPECTION'
echo '============================================================'
echo
echo "RUN=$RUN"
echo "OUTPUT=$OUT"

echo
echo '[1] PRECONDITION'

C5_RESULT_FILE="$C5/09-verification/result.tsv"
C7_RESULT_FILE="$C7/05-verification/result.tsv"

C5_CELL4="$("$BIN/awk" '$1=="CELL4_RESULT"{print $2; exit}' "$C5_RESULT_FILE" 2>/dev/null)"
C5_FAIL="$("$BIN/awk" '$1=="FAIL_COUNT"{print $2; exit}' "$C5_RESULT_FILE" 2>/dev/null)"
C7_RESULT="$("$BIN/awk" '$1=="RESULT"{print $2; exit}' "$C7_RESULT_FILE" 2>/dev/null)"

if [[ "$C5_CELL4" == "CELL_4_PASS" && "$C5_FAIL" == "0" ]]; then
    C5_RESULT="CELL_5_PASS"
else
    C5_RESULT=""
fi

echo "CELL5_RESULT=$C5_RESULT"
echo "CELL7_RESULT=$C7_RESULT"

if [[ "$C5_RESULT" != "CELL_5_PASS" ]]; then
    FAIL=$((FAIL+1))
fi

if [[ "$C7_RESULT" != "CELL_7_PASS" ]]; then
    FAIL=$((FAIL+1))
fi

if (( FAIL == 0 )); then
    echo 'PRECONDITION=PASS'
else
    echo 'PRECONDITION=FAIL'
fi

echo
echo '[2] SAFETY'

"$BIN/cat" > "$OUT/01-input/safety.tsv" <<'EOF'
SOURCE_MODIFY	NO
SOURCE_DELETE	NO
SOURCE_MOVE	NO
SOURCE_RENAME	NO
SOURCE_QUARANTINE	NO
MEMBERSHIP_MODIFY	NO
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

"$BIN/cat" "$OUT/01-input/safety.tsv"

echo
echo '[3] GAP INPUT'

GAP_FILE="$C4/06-gaps/unassigned.tsv"

if [[ ! -f "$GAP_FILE" ]]; then
    echo 'GAP_FILE=MISSING'
    FAIL=$((FAIL+1))
    GAP_COUNT=0
else
    GAP_COUNT="$("$BIN/awk" 'NF>=4{n++} END{print n+0}' "$GAP_FILE")"
fi

echo "GAP_COUNT=$GAP_COUNT"

if [[ "$GAP_COUNT" == "8" ]]; then
    echo 'GAP_COUNT_CHECK=PASS'
else
    echo 'GAP_COUNT_CHECK=FAIL'
    FAIL=$((FAIL+1))
fi

echo
echo '[4] TARGETED CONTENT INSPECTION'

POOL_ROOT="$R/11-molecules/resource-pool"
RELATION_FILE="$C4/03-relations/relation-map.tsv"

"$BIN/cat" > "$OUT/02-inspection/inspection.tsv" <<'EOF'
resource	pool	path	bytes	binary	m0001	m0002	m0003	m0004	relation	best	confidence	reason
EOF

INSPECTED=0

while IFS=$'\t' read -r RESOURCE SIZE POOL PATH REST; do

    [[ -z "$RESOURCE" ]] && continue
    [[ "$RESOURCE" == "resource" ]] && continue

    INSPECTED=$((INSPECTED+1))

    BYTES=0
    BINARY=0
    M0001=0
    M0002=0
    M0003=0
    M0004=0
    RELATION=0

    if [[ -f "$PATH" ]]; then
        BYTES="$("$BIN/wc" -c < "$PATH" 2>/dev/null)"
        [[ "$BYTES" =~ '^[0-9]+$' ]] || BYTES=0

        SAMPLE="$("$BIN/head" -c 32768 "$PATH" 2>/dev/null | \
          "$BIN/tr" -d '\000\r' 2>/dev/null)"

        if [[ -n "$SAMPLE" ]]; then

            if printf '%s' "$SAMPLE" | "$BIN/grep" -Eq '[^[:print:][:space:]]'; then
                BINARY=1
            fi

            M0001=$(printf '%s\n' "$SAMPLE" | \
                "$BIN/grep" -Eio \
                '(^|[^A-Za-z])(patch|diff|configure\.ac|ac_add_options)([^A-Za-z]|$)' | \
                "$BIN/wc" -l)

            M0002=$(printf '%s\n' "$SAMPLE" | \
                "$BIN/grep" -Eio \
                '<[A-Za-z][^>]*>|<\?xml|xmlns=' | \
                "$BIN/wc" -l)

            M0003=$(printf '%s\n' "$SAMPLE" | \
                "$BIN/grep" -Eio \
                'cmake|CMakeLists|add_library|add_executable|make|ninja|meson' | \
                "$BIN/wc" -l)

            M0004=$(printf '%s\n' "$SAMPLE" | \
                "$BIN/grep" -Eio \
                'manifest|documentation|readme|license|copyright|description' | \
                "$BIN/wc" -l)

            [[ "$M0001" =~ '^[0-9]+$' ]] || M0001=0
            [[ "$M0002" =~ '^[0-9]+$' ]] || M0002=0
            [[ "$M0003" =~ '^[0-9]+$' ]] || M0003=0
            [[ "$M0004" =~ '^[0-9]+$' ]] || M0004=0
        fi
    fi

    if [[ -f "$RELATION_FILE" ]]; then
        RELATION="$("$BIN/awk" -v r="$RESOURCE" '$6==r{n++} END{print n+0}' "$RELATION_FILE")"
    fi

    BEST=M0000
    MAX=0
    SECOND=0

    for pair in \
        "M0001:$M0001" \
        "M0002:$M0002" \
        "M0003:$M0003" \
        "M0004:$M0004"
    do
        MOL="${pair%%:*}"
        VAL="${pair#*:}"

        if (( VAL > MAX )); then
            SECOND=$MAX
            MAX=$VAL
            BEST=$MOL
        elif (( VAL > SECOND )); then
            SECOND=$VAL
        fi
    done

    if (( MAX == 0 )); then
        CONFIDENCE=LOW
        REASON=NO_CONTENT_SIGNAL
    elif (( MAX >= 2 && MAX > SECOND )); then
        CONFIDENCE=STRONG
        REASON=DOMINANT_CONTENT_SIGNAL
    elif (( MAX >= 2 )); then
        CONFIDENCE=MEDIUM
        REASON=COMPETING_CONTENT_SIGNAL
    else
        CONFIDENCE=MEDIUM
        REASON=SINGLE_CONTENT_SIGNAL
    fi

    if (( BINARY == 1 )); then
        CONFIDENCE=LOW
        REASON=BINARY_CONTENT_REVIEW
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$RESOURCE" \
        "$POOL" \
        "$PATH" \
        "$BYTES" \
        "$BINARY" \
        "$M0001" \
        "$M0002" \
        "$M0003" \
        "$M0004" \
        "$RELATION" \
        "$BEST" \
        "$CONFIDENCE" \
        "$REASON" \
        >> "$OUT/02-inspection/inspection.tsv"

done < "$GAP_FILE"

echo
"$BIN/cat" "$OUT/02-inspection/inspection.tsv"

echo
echo '[5] EVIDENCE SUMMARY'

STRONG="$("$BIN/awk" 'NR>1 && $12=="STRONG"{n++} END{print n+0}' "$OUT/02-inspection/inspection.tsv")"
MEDIUM="$("$BIN/awk" 'NR>1 && $12=="MEDIUM"{n++} END{print n+0}' "$OUT/02-inspection/inspection.tsv")"
LOW="$("$BIN/awk" 'NR>1 && $12=="LOW"{n++} END{print n+0}' "$OUT/02-inspection/inspection.tsv")"

echo "STRONG=$STRONG"
echo "MEDIUM=$MEDIUM"
echo "LOW=$LOW"

echo
echo '[6] MAP PROPOSALS'

"$BIN/awk" -F '\t' '
NR>1 && ($12=="STRONG" || $12=="MEDIUM") {
    print $1 "\t" $11 "\t" $12 "\t" $10 "\t" $13
}
' "$OUT/02-inspection/inspection.tsv" \
> "$OUT/04-decisions/map-proposals.tsv"

MAP_COUNT="$("$BIN/wc" -l < "$OUT/04-decisions/map-proposals.tsv")"

echo "MAP_PROPOSALS=$MAP_COUNT"
"$BIN/cat" "$OUT/04-decisions/map-proposals.tsv"

echo
echo '[7] HOLD / OBSERVE'

"$BIN/awk" -F '\t' '
NR>1 && $12=="LOW" {
    print $1 "\t" $11 "\t" $12 "\tOBSERVE\t" $13
}
NR>1 && $12=="MEDIUM" {
    print $1 "\t" $11 "\t" $12 "\tHOLD_REVIEW\t" $13
}
' "$OUT/02-inspection/inspection.tsv" \
> "$OUT/04-decisions/review.tsv"

"$BIN/cat" "$OUT/04-decisions/review.tsv"

echo
echo '[8] CONSERVATION'

if (( INSPECTED == GAP_COUNT )); then
    CONSERVATION=PASS
else
    CONSERVATION=FAIL
    FAIL=$((FAIL+1))
fi

echo "INPUT_GAPS=$GAP_COUNT"
echo "INSPECTED=$INSPECTED"
echo "INSPECTION_CONSERVATION=$CONSERVATION"

echo
echo '[9] PRESERVATION'

echo 'SOURCE_MODIFY=NO'
echo 'SOURCE_DELETE=NO'
echo 'SOURCE_MOVE=NO'
echo 'SOURCE_RENAME=NO'
echo 'SOURCE_QUARANTINE=NO'
echo 'MEMBERSHIP_MODIFY=NO'
echo 'DNA_MUTATION=NO'
echo 'RESOURCE_EXECUTE=NO'
echo 'PROCESS_KILL=NO'
echo 'DECAY=NO'
echo 'DELETE=NO'
echo 'REPLACE=NO'

echo
echo '[10] FINAL GATE'

if (( FAIL == 0 )); then
    RESULT=CELL_8_PASS
else
    RESULT=CELL_8_FAIL
fi

"$BIN/cat" > "$OUT/05-verification/result.tsv" <<EOF
RESULT	$RESULT
GAP_INPUT	$GAP_COUNT
INSPECTED	$INSPECTED
STRONG	$STRONG
MEDIUM	$MEDIUM
LOW	$LOW
MAP_PROPOSALS	$MAP_COUNT
SOURCE_DATA	INTACT
MEMBERSHIP_MODIFY	NO
DNA_MUTATION	NO
RESOURCE_EXECUTE	NO
DELETE	NO
DECAY	NO
REPLACE	NO
RIGHTS	INHERITED_ONLY
EOF

echo "RESULT=$RESULT"
echo "FAIL_COUNT=$FAIL"

echo
echo '============================================================'
echo ' CELL 8 COMPLETE'
echo " RESULT=$RESULT"
echo " CHECKPOINT=$OUT"
echo ' SOURCE_DATA=INTACT'
echo ' MEMBERSHIP_MODIFY=NO'
echo ' DNA=UNCHANGED'
echo ' LINEAGE=PRESERVED'
echo ' NEXT=CELL_9'
echo '============================================================'
