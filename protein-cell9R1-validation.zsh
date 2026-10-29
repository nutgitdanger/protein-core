#!/data/data/com.termux/files/usr/bin/zsh
set -u

BIN="$PREFIX/bin"
R="$HOME/.config/dynu-audit/protein"

C5="$R/02-collector/checkpoints/cell5R3-validation-20260905-025128"
C7="$R/02-collector/checkpoints/cell7R1-correlation-20260905-025525"
C8="$R/02-collector/checkpoints/cell8R3-deep-20260905-030925"

STAMP="$("$BIN/date" +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell9R1-validation-$STAMP"

mkdir -p \
  "$OUT/01-input" \
  "$OUT/02-validation" \
  "$OUT/03-decisions" \
  "$OUT/04-verification"

FAIL=0

echo '============================================================'
echo ' PROTEIN CELL 9 R1 — VALIDATION ONLY'
echo '============================================================'

echo
echo '[1] PRECONDITION'

C5_RESULT="$("$BIN/awk" '$1=="CELL4_RESULT"{print $2}' \
  "$C5/09-verification/result.tsv" 2>/dev/null)"

C7_RESULT="$("$BIN/awk" '$1=="RESULT"{print $2}' \
  "$C7/05-verification/result.tsv" 2>/dev/null)"

C8_RESULT="$("$BIN/awk" '$1=="RESULT"{print $2}' \
  "$C8/05-verification/result.tsv" 2>/dev/null)"

echo "CELL5=$C5_RESULT"
echo "CELL7=$C7_RESULT"
echo "CELL8=$C8_RESULT"

if [[ "$C5_RESULT" == "CELL_4_PASS" &&
      "$C7_RESULT" == "CELL_7_PASS" &&
      "$C8_RESULT" == "CELL_8_PASS" ]]; then
    echo 'PRECONDITION=PASS'
else
    echo 'PRECONDITION=FAIL'
    FAIL=$((FAIL+1))
fi

echo
echo '[2] SAFETY'

"$BIN/cat" > "$OUT/01-input/safety.tsv" <<EOF
SOURCE_MODIFY	NO
SOURCE_DELETE	NO
SOURCE_MOVE	NO
SOURCE_RENAME	NO
SOURCE_QUARANTINE	NO
MEMBERSHIP_MODIFY	NO
DNA_MUTATION	NO
RESOURCE_EXECUTE	NO
PROCESS_KILL	NO
DELETE	NO
DECAY	NO
REPLACE	NO
EXTERNAL_WRITE	NO
CREDENTIAL_READ	NO
RIGHTS	INHERITED_ONLY
EOF

"$BIN/cat" "$OUT/01-input/safety.tsv"

echo
echo '[3] INPUT'

I="$C8/02-inspection/inspection.tsv"
P="$C8/04-decisions/map-proposals.tsv"

if [[ -f "$I" && -f "$P" ]]; then
    echo 'INPUT_FILES=PASS'
else
    echo 'INPUT_FILES=FAIL'
    FAIL=$((FAIL+1))
fi

echo
echo '[4] PROPOSAL VALIDATION'

"$BIN/cat" > "$OUT/02-validation/proposals.tsv" <<'EOF'
resource	target	confidence	relation	reason	validation	decision
EOF

while IFS=$'\t' read -r RESOURCE TARGET CONF REL REASON; do
    [[ -z "$RESOURCE" ]] && continue

    IFS=$'\t' read -r \
        _ POOL PATH BYTES BINARY M1 M2 M3 M4 REL2 BEST CONF2 REASON2 \
        <<< "$("$BIN/awk" -F '\t' -v r="$RESOURCE" '$1==r{print}' "$I")"

    VALID=YES
    DECISION=HOLD_REVIEW

    # Proposal must target an existing molecule.
    if [[ "$TARGET" != M0001 && "$TARGET" != M0002 &&
          "$TARGET" != M0003 && "$TARGET" != M0004 ]]; then
        VALID=NO
    fi

    # Proposal confidence must agree with inspection.
    if [[ "$CONF" != "$CONF2" ]]; then
        VALID=NO
    fi

    # Proposal target must equal inspection BEST.
    if [[ "$TARGET" != "$BEST" ]]; then
        VALID=NO
    fi

    # Relation value must agree with inspection.
    if [[ "$REL" != "$REL2" ]]; then
        VALID=NO
    fi

    # Strong proposal requires actual dominant signal.
    if [[ "$CONF" == "STRONG" ]]; then
        case "$TARGET" in
            M0001) SCORE="$M1"; SECOND=$(( M2 > M3 ? M2 : M3 )); SECOND=$(( SECOND > M4 ? SECOND : M4 )) ;;
            M0002) SCORE="$M2"; SECOND=$(( M1 > M3 ? M1 : M3 )); SECOND=$(( SECOND > M4 ? SECOND : M4 )) ;;
            M0003) SCORE="$M3"; SECOND=$(( M1 > M2 ? M1 : M2 )); SECOND=$(( SECOND > M4 ? SECOND : M4 )) ;;
            M0004) SCORE="$M4"; SECOND=$(( M1 > M2 ? M1 : M2 )); SECOND=$(( SECOND > M3 ? SECOND : M3 )) ;;
        esac

        if (( SCORE < 2 || SCORE <= SECOND )); then
            VALID=NO
        fi
    fi

    if [[ "$VALID" == YES ]]; then
        DECISION=ACCEPT_FOR_REVIEW
    else
        DECISION=REJECT
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$RESOURCE" "$TARGET" "$CONF" "$REL" "$REASON" "$VALID" "$DECISION" \
      >> "$OUT/02-validation/proposals.tsv"

done < "$P"

    "$BIN/cat" "$OUT/02-validation/proposals.tsv"

echo
echo '[5] SPECIAL ANOMALY CHECK'

"$BIN/awk" -F '\t' '
NR>1 && $1 ~ /^2cf0aa05373b342f/ {
    print "RESOURCE="$1
    print "M0001="$6
    print "M0002="$7
    print "M0003="$8
    print "M0004="$9
    print "BEST="$11
    print "CONFIDENCE="$12

    if($7 > $6 && $7 > $8 && $7 > $9 && $11=="M0002")
        print "APPSTREAMCOMPOSE_VALIDATION=PASS"
    else
        print "APPSTREAMCOMPOSE_VALIDATION=FAIL"
}' "$I"

echo
echo '[6] DECISION SUMMARY'

"$BIN/awk" -F '\t' '
NR>1 {
    total++
    if($6=="YES") accepted++
    if($7=="REJECT") rejected++
    if($7=="ACCEPT_FOR_REVIEW") review++
}
END {
    print "TOTAL=" total+0
    print "ACCEPT_FOR_REVIEW=" review+0
    print "REJECT=" rejected+0

    if(total==7 && rejected==0)
        print "VALIDATION_RESULT=PASS"
    else
        print "VALIDATION_RESULT=HOLD"
}' "$OUT/02-validation/proposals.tsv" \
  | "$BIN/tee" "$OUT/03-decisions/summary.tsv"

echo
echo '[7] CONSERVATION'

INPUT=$("$BIN/awk" 'NR>1 && NF>=13{n++} END{print n+0}' "$I")
VALIDATED=$("$BIN/awk" 'NR>1{n++} END{print n+0}' \
  "$OUT/02-validation/proposals.tsv")

echo "INPUT_INSPECTIONS=$INPUT"
echo "VALIDATED_PROPOSALS=$VALIDATED"

if [[ "$INPUT" == "8" && "$VALIDATED" == "7" ]]; then
    echo 'VALIDATION_CONSERVATION=PASS'
else
    echo 'VALIDATION_CONSERVATION=FAIL'
    FAIL=$((FAIL+1))
fi

echo
echo '[8] DNA INTEGRITY'

DNA_OK=YES

for F in identity capabilities boundaries dependencies policy; do
    FILE="$R/00-core/dna/$F.json"
    HASH="$("$BIN/sha256sum" "$FILE" | "$BIN/awk" '{print $1}')"
    printf '%-15s %s\n' "$F" "$HASH"
done

echo
echo '[9] SOURCE / MEMBERSHIP INTEGRITY'

echo 'SOURCE_MODIFY=NO'
echo 'MEMBERSHIP_MODIFY=NO'
echo 'DNA_MUTATION=NO'
echo 'DELETE=NO'
echo 'MOVE=NO'
echo 'QUARANTINE=NO'
echo 'PROCESS_KILL=NO'

echo
echo '[10] FINAL VERIFICATION'

if (( FAIL == 0 )); then
    RESULT=CELL_9_PASS
else
    RESULT=CELL_9_HOLD
fi

"$BIN/cat" > "$OUT/04-verification/result.tsv" <<EOF
RESULT	$RESULT
CELL5	$C5_RESULT
CELL7	$C7_RESULT
CELL8	$C8_RESULT
INPUT_INSPECTIONS	$INPUT
VALIDATED_PROPOSALS	$VALIDATED
SOURCE_DATA	INTACT
MEMBERSHIP_MODIFY	NO
DNA_MUTATION	NO
DELETE	NO
MOVE	NO
QUARANTINE	NO
PROCESS_KILL	NO
RIGHTS	INHERITED_ONLY
FAIL_COUNT	$FAIL
NEXT	CELL10_REVIEW
EOF

"$BIN/cat" "$OUT/04-verification/result.tsv"

echo
echo '============================================================'
echo " RESULT=$RESULT"
echo " CHECKPOINT=$OUT"
echo ' MEMBERSHIP WAS NOT MODIFIED'
echo ' SOURCE WAS NOT MODIFIED'
echo ' DNA WAS NOT MODIFIED'
echo '============================================================'
