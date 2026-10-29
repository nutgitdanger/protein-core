#!/data/data/com.termux/files/usr/bin/zsh

export PATH="/data/data/com.termux/files/usr/bin:$HOME/bin:/system/bin:/system/xbin"
rehash 2>/dev/null

R="$HOME/.config/dynu-audit/protein"
C4="$R/02-collector/checkpoints/cell4R3-dependency-20260905-024119"
C5="$R/02-collector/checkpoints/cell5R3-validation-20260905-025128"
C6="$R/02-collector/checkpoints/cell6R1-gap-20260905-025357"
C7="$R/02-collector/checkpoints/cell7R1-correlation-20260905-025525"

RUN="$(date +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell8R1-deep-$RUN"

mkdir -p "$OUT"/{01-input,02-inspection,03-evidence,04-decisions,05-verification}

echo '============================================================'
echo ' PROTEIN — CELL 8 R1 — TARGETED DEEP INSPECTION'
echo '============================================================'
echo
echo "RUN=$RUN"
echo "CELL7=$C7"
echo "OUTPUT=$OUT"

FAIL=0

echo
echo '[1] PRECONDITION'

CELL5_RESULT="$(awk '$1=="RESULT"{print $2; exit}' "$C5/14-final-gate/result.tsv" 2>/dev/null)"
[[ "$CELL5_RESULT" == "CELL_5_PASS" ]] \
  && echo 'CELL5_RESULT=CELL_5_PASS' \
  || { echo "CELL5_RESULT=$CELL5_RESULT"; FAIL=$((FAIL+1)); }

CELL7_RESULT="$(awk '$1=="RESULT"{print $2; exit}' "$C7/result.tsv" 2>/dev/null)"
[[ "$CELL7_RESULT" == "CELL_7_PASS" ]] \
  && echo 'CELL7_RESULT=CELL_7_PASS' \
  || { echo "CELL7_RESULT=$CELL7_RESULT"; FAIL=$((FAIL+1)); }

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

cat "$OUT/01-input/safety.tsv"

echo
echo '[3] INPUT GAPS'

GAP="$C4/06-gaps/unassigned.tsv"

[[ -s "$GAP" ]] || { echo 'GAP_INPUT=FAIL'; FAIL=$((FAIL+1)); }

cp "$GAP" "$OUT/01-input/unassigned.tsv"

GAP_COUNT="$(wc -l < "$GAP" | tr -d ' ')"
echo "GAP_COUNT=$GAP_COUNT"

[[ "$GAP_COUNT" == "8" ]] \
  && echo 'GAP_COUNT_CHECK=PASS' \
  || { echo 'GAP_COUNT_CHECK=FAIL'; FAIL=$((FAIL+1)); }

echo
echo '[4] TARGETED CONTENT INSPECTION'

echo -e "resource\tpath\tbytes\tbinary\tm0001_signal\tm0002_signal\tm0003_signal\tm0004_signal\tbest\tconfidence\treason" \
  > "$OUT/02-inspection/inspection.tsv"

while IFS=$'\t' read -r resource size pool path rest; do

    [[ -z "$resource" ]] && continue
    [[ -f "$path" ]] || {
        echo -e "$resource\t$path\t0\tMISSING\t0\t0\t0\t0\tNONE\tLOW\tSOURCE_NOT_FOUND" \
          >> "$OUT/02-inspection/inspection.tsv"
        continue
    }

    bytes="$(wc -c < "$path" | tr -d ' ')"

    sample="$(
        LC_ALL=C head -c 32768 "$path" 2>/dev/null |
        tr '\000' ' ' |
        tr '\r' ' '
    )"

    binary=0
    LC_ALL=C printf '%s' "$sample" | grep -q '[^ -~	]' && binary=1

    s1=0
    s2=0
    s3=0
    s4=0

    # M0001 PATCH / BUILD PATCH
    printf '%s\n' "$sample" | grep -Eqi \
      '(^|[[:space:]])(diff --git|@@|---[[:space:]]|+++[[:space:]]|patch|PATCH FILE|ac_add_options|configure\.ac)' \
      && s1=1

    # M0002 STRUCTURED DATA / XML
    printf '%s\n' "$sample" | grep -Eqi \
      '(<\?xml|<[^>]+>|</[^>]+>|DOCTYPE|xmlns=|<component|<property)' \
      && s2=1

    # M0003 BUILD CAPABILITY
    printf '%s\n' "$sample" | grep -Eqi \
      '(cmake_minimum_required|project[[:space:]]*\(|add_library|add_executable|CMAKE_|makefile|configure[[:space:]]|#!/.*(sh|bash)|gcc|clang|meson|ninja)' \
      && s3=1

    # M0004 DOCUMENTATION
    printf '%s\n' "$sample" | grep -Eqi \
      '(^|[[:space:]])(manifest|documentation|license|copyright|description|readme|usage|version|author)([[:space:]:=]|$)' \
      && s4=1

    best=M0000
    confidence=LOW
    reason=NO_CONTENT_SIGNAL

    scores="$s1 $s2 $s3 $s4"
    max=0
    idx=0
    i=0

    for x in $scores; do
        i=$((i+1))
        if (( x > max )); then
            max=$x
            idx=$i
        fi
    done

    case "$idx" in
        1) best=M0001 ;;
        2) best=M0002 ;;
        3) best=M0003 ;;
        4) best=M0004 ;;
    esac

    if (( max >= 1 )); then
        confidence=MEDIUM
        reason=CONTENT_SIGNAL
    fi

    # Strong evidence requires at least two independent content indicators.
    signal_count=$((s1+s2+s3+s4))
    if (( signal_count >= 2 )); then
        confidence=STRONG
        reason=MULTI_SIGNAL_CONTENT
    fi

    echo -e "$resource\t$path\t$bytes\t$binary\t$s1\t$s2\t$s3\t$s4\t$best\t$confidence\t$reason" \
      >> "$OUT/02-inspection/inspection.tsv"

done < "$GAP"

cat "$OUT/02-inspection/inspection.tsv"

echo
echo '[5] EVIDENCE SUMMARY'

STRONG="$(awk -F'\t' 'NR>1 && $10=="STRONG"{n++} END{print n+0}' "$OUT/02-inspection/inspection.tsv")"
MEDIUM="$(awk -F'\t' 'NR>1 && $10=="MEDIUM"{n++} END{print n+0}' "$OUT/02-inspection/inspection.tsv")"
LOW="$(awk -F'\t' 'NR>1 && $10=="LOW"{n++} END{print n+0}' "$OUT/02-inspection/inspection.tsv")"

echo "STRONG=$STRONG"
echo "MEDIUM=$MEDIUM"
echo "LOW=$LOW"

echo
echo '[6] MAP PROPOSALS'

echo -e "resource\tproposed_molecule\tconfidence\treason" \
  > "$OUT/04-decisions/map-proposals.tsv"

awk -F'\t' '
NR>1 && $10=="STRONG" {
    print $1 "\t" $9 "\t" $10 "\t" $11
}' "$OUT/02-inspection/inspection.tsv" \
  >> "$OUT/04-decisions/map-proposals.tsv"

MAP_COUNT="$(awk 'NR>1{n++} END{print n+0}' "$OUT/04-decisions/map-proposals.tsv")"
echo "MAP_PROPOSALS=$MAP_COUNT"

echo
echo '[7] HOLD / OBSERVE'

echo -e "resource\tproposed_molecule\tconfidence\taction\treason" \
  > "$OUT/04-decisions/review.tsv"

awk -F'\t' '
NR>1 && $10=="MEDIUM" {
    print $1 "\t" $9 "\t" $10 "\tHOLD_REVIEW\t" $11
}
NR>1 && $10=="LOW" {
    print $1 "\t" $9 "\t" $10 "\tOBSERVE\t" $11
}' "$OUT/02-inspection/inspection.tsv" \
  >> "$OUT/04-decisions/review.tsv"

awk -F'\t' '$4=="HOLD_REVIEW"{n++} END{print "HOLD_REVIEW=" n+0}' \
  "$OUT/04-decisions/review.tsv"

awk -F'\t' '$4=="OBSERVE"{n++} END{print "OBSERVE=" n+0}' \
  "$OUT/04-decisions/review.tsv"

echo
echo '[8] CONSERVATION'

INSPECTED="$(awk 'NR>1{n++} END{print n+0}' "$OUT/02-inspection/inspection.tsv")"

echo "INPUT_GAPS=$GAP_COUNT"
echo "INSPECTED=$INSPECTED"

if [[ "$GAP_COUNT" == "$INSPECTED" ]]; then
    echo 'INSPECTION_CONSERVATION=PASS'
else
    echo 'INSPECTION_CONSERVATION=FAIL'
    FAIL=$((FAIL+1))
fi

echo
echo '[9] SOURCE / MEMBERSHIP PRESERVATION'

echo 'SOURCE_MODIFY=NO'
echo 'SOURCE_DELETE=NO'
echo 'SOURCE_MOVE=NO'
echo 'SOURCE_RENAME=NO'
echo 'SOURCE_QUARANTINE=NO'
echo 'MEMBERSHIP_MODIFY=NO'
echo 'DNA_MUTATION=NO'
echo 'RESOURCE_EXECUTE=NO'

echo
echo '[10] FINAL GATE'

if (( FAIL == 0 )); then
    RESULT=CELL_8_PASS
else
    RESULT=CELL_8_FAIL
fi

cat > "$OUT/05-verification/result.tsv" <<EOF
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
RIGHTS	INHERITED_ONLY
EOF

echo "RESULT=$RESULT"
echo "FAIL_COUNT=$FAIL"

echo
echo '============================================================'
echo " CELL 8 COMPLETE"
echo " RESULT=$RESULT"
echo " CHECKPOINT=$OUT"
echo " SOURCE_DATA=INTACT"
echo " MEMBERSHIP_MODIFY=NO"
echo " DNA=UNCHANGED"
echo " LINEAGE=PRESERVED"
echo " NEXT=CELL_9"
echo '============================================================'
