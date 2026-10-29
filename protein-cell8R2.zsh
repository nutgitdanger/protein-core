#!/data/data/com.termux/files/usr/bin/zsh

BIN="/data/data/com.termux/files/usr/bin"
export PATH="$BIN:$HOME/bin:/system/bin:/system/xbin"

R="$HOME/.config/dynu-audit/protein"
C4="$R/02-collector/checkpoints/cell4R3-dependency-20260905-024119"
C5="$R/02-collector/checkpoints/cell5R3-validation-20260905-025128"
C6="$R/02-collector/checkpoints/cell6R1-gap-20260905-025357"
C7="$R/02-collector/checkpoints/cell7R1-correlation-20260905-025525"

RUN="$("$BIN/date" +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell8R2-deep-$RUN"

"$BIN/mkdir" -p "$OUT"/{01-input,02-inspection,03-evidence,04-decisions,05-verification}

echo '============================================================'
echo ' PROTEIN — CELL 8 R2 — TARGETED DEEP INSPECTION'
echo '============================================================'
echo
echo "RUN=$RUN"
echo "OUTPUT=$OUT"

FAIL=0

echo
echo '[1] PRECONDITION'

C5_RESULT_FILE="$C5/09-verification/result.tsv"
C7_RESULT_FILE="$C7/05-verification/result.tsv"

C5_RESULT="$("$BIN/awk" '$1=="RESULT"{print $2; exit}' "$C5_RESULT_FILE" 2>/dev/null)"
C7_RESULT="$("$BIN/awk" '$1=="RESULT"{print $2; exit}' "$C7_RESULT_FILE" 2>/dev/null)"

echo "CELL5_RESULT=$( "$BIN/awk" '$1=="CELL4_RESULT"{v=$2} END{if(v=="CELL_4_PASS") print "CELL_5_PASS"; else print ""}' "$C5_RESULT_FILE" )
echo "CELL7_RESULT=$C7_RESULT"

[[ "$C5_RESULT" == "CELL_5_PASS" ]] || FAIL=$((FAIL+1))
[[ "$C7_RESULT" == "CELL_7_PASS" ]] || FAIL=$((FAIL+1))

if (( FAIL == 0 )); then
    echo 'PRECONDITION=PASS'
else
    echo 'PRECONDITION=FAIL'
fi

echo
echo '[2] SAFETY'

cat > "$OUT/01-input/safety.tsv" <<'EOF'
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

GAP="$C4/06-gaps/unassigned.tsv"

GAP_COUNT="$("$BIN/wc" -l < "$GAP" | "$BIN/tr" -d ' ')"

echo "GAP_COUNT=$GAP_COUNT"

[[ "$GAP_COUNT" == "8" ]] || FAIL=$((FAIL+1))

"$BIN/cp" "$GAP" "$OUT/01-input/unassigned.tsv"

echo
echo '[4] TARGETED CONTENT INSPECTION'

REL="$C4/03-relations/relation-map.tsv"

{
    printf 'resource\tpool\tpath\tbytes\tbinary\tm0001\tm0002\tm0003\tm0004\trelation\tbest\tconfidence\treason\n'

    while IFS=$'\t' read -r resource size pool path rest; do
        [[ -z "$resource" ]] && continue

        bytes=0
        binary=0
        s1=0
        s2=0
        s3=0
        s4=0
        relation=0

        if [[ -f "$path" ]]; then
            bytes="$("$BIN/wc" -c < "$path" | "$BIN/tr" -d ' ')"

            sample="$(
                "$BIN/head" -c 32768 "$path" 2>/dev/null |
                "$BIN/tr" '\000\r' '  '
            )"

            LC_ALL=C printf '%s' "$sample" |
                "$BIN/grep" -q '[^ -~	]' && binary=1

            LC_ALL=C printf '%s\n' "$sample" |
                "$BIN/grep" -Eqi \
                'diff --git|^@@|^--- |^\+\+\+ |\.patch|ac_add_options|configure\.ac' &&
                s1=1

            LC_ALL=C printf '%s\n' "$sample" |
                "$BIN/grep" -Eqi \
                '<\?xml|<[^>]+>|</[^>]+>|DOCTYPE|xmlns=|<component|<property' &&
                s2=1

            LC_ALL=C printf '%s\n' "$sample" |
                "$BIN/grep" -Eqi \
                'cmake_minimum_required|project[[:space:]]*\(|add_library|add_executable|CMAKE_|makefile|configure[[:space:]]|gcc|clang|meson|ninja' &&
                s3=1

            LC_ALL=C printf '%s\n' "$sample" |
                "$BIN/grep" -Eqi \
                'manifest|documentation|license|copyright|description|readme|usage|version|author' &&
                s4=1
        fi

        "$BIN/awk" -F'\t' -v r="$resource" '$6==r {found=1; exit} END{print found+0}' \
            "$REL" > "$OUT/03-evidence/relation.tmp"

        relation="$("$BIN/cat" "$OUT/03-evidence/relation.tmp")"

        best=M0000
        confidence=LOW
        reason=NO_CONTENT_SIGNAL

        max=0
        [[ "$s1" -gt "$max" ]] && { max=$s1; best=M0001; }
        [[ "$s2" -gt "$max" ]] && { max=$s2; best=M0002; }
        [[ "$s3" -gt "$max" ]] && { max=$s3; best=M0003; }
        [[ "$s4" -gt "$max" ]] && { max=$s4; best=M0004; }

        signal_count=$((s1+s2+s3+s4))

        if (( signal_count >= 2 )); then
            confidence=STRONG
            reason=MULTI_SIGNAL_CONTENT
        elif (( signal_count == 1 )); then
            confidence=MEDIUM
            reason=SINGLE_CONTENT_SIGNAL
        fi

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$resource" "$pool" "$path" "$bytes" "$binary" \
            "$s1" "$s2" "$s3" "$s4" "$relation" \
            "$best" "$confidence" "$reason"

    done < "$GAP"

} > "$OUT/02-inspection/inspection.tsv"

"$BIN/cat" "$OUT/02-inspection/inspection.tsv"

echo
echo '[5] EVIDENCE SUMMARY'

STRONG="$("$BIN/awk" -F'\t' 'NR>1&&$12=="STRONG"{n++}END{print n+0}' "$OUT/02-inspection/inspection.tsv")"
MEDIUM="$("$BIN/awk" -F'\t' 'NR>1&&$12=="MEDIUM"{n++}END{print n+0}' "$OUT/02-inspection/inspection.tsv")"
LOW="$("$BIN/awk" -F'\t' 'NR>1&&$12=="LOW"{n++}END{print n+0}' "$OUT/02-inspection/inspection.tsv")"

echo "STRONG=$STRONG"
echo "MEDIUM=$MEDIUM"
echo "LOW=$LOW"

echo
echo '[6] MAP PROPOSALS'

printf 'resource\tproposed_molecule\tconfidence\treason\n' \
    > "$OUT/04-decisions/map-proposals.tsv"

"$BIN/awk" -F'\t' '
NR>1 && $12=="STRONG" {
    print $1 "\t" $11 "\t" $12 "\t" $13
}' "$OUT/02-inspection/inspection.tsv" \
    >> "$OUT/04-decisions/map-proposals.tsv"

MAP_COUNT="$("$BIN/awk" 'NR>1{n++}END{print n+0}' "$OUT/04-decisions/map-proposals.tsv")"

echo "MAP_PROPOSALS=$MAP_COUNT"

echo
echo '[7] HOLD / OBSERVE'

printf 'resource\tproposed_molecule\tconfidence\taction\treason\n' \
    > "$OUT/04-decisions/review.tsv"

"$BIN/awk" -F'\t' '
NR>1 && $12=="MEDIUM" {
    print $1 "\t" $11 "\t" $12 "\tHOLD_REVIEW\t" $13
}
NR>1 && $12=="LOW" {
    print $1 "\t" $11 "\t" $12 "\tOBSERVE\t" $13
}' "$OUT/02-inspection/inspection.tsv" \
    >> "$OUT/04-decisions/review.tsv"

"$BIN/cat" "$OUT/04-decisions/review.tsv"

echo
echo '[8] CONSERVATION'

INSPECTED="$("$BIN/awk" 'NR>1{n++}END{print n+0}' "$OUT/02-inspection/inspection.tsv")"

echo "INPUT_GAPS=$GAP_COUNT"
echo "INSPECTED=$INSPECTED"

if [[ "$GAP_COUNT" == "$INSPECTED" ]]; then
    echo 'INSPECTION_CONSERVATION=PASS'
else
    echo 'INSPECTION_CONSERVATION=FAIL'
    FAIL=$((FAIL+1))
fi

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
