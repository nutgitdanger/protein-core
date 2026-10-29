#!/data/data/com.termux/files/usr/bin/zsh

export PATH="/data/data/com.termux/files/usr/bin:$HOME/bin:/system/bin:/system/xbin"
rehash

R="$HOME/.config/dynu-audit/protein"
C4="$R/02-collector/checkpoints/cell4R3-dependency-20260905-024119"
C5="$R/02-collector/checkpoints/cell5R3-validation-20260905-025128"
C6="$R/02-collector/checkpoints/cell6R1-gap-20260905-025357"

RUN="$(date +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell7R1-correlation-$RUN"

mkdir -p "$OUT"/{01-input,02-correlation,03-evidence,04-decisions,05-verification}

echo '============================================================'
echo ' PROTEIN — CELL 7 R1 — CORRELATION / EVIDENCE DEEPENING'
echo '============================================================'
echo
echo "RUN=$RUN"
echo "CELL4=$C4"
echo "CELL5=$C5"
echo "CELL6=$C6"
echo "OUTPUT=$OUT"

FAIL=0

echo
echo '[1] PRECONDITION'

CELL5_RESULT="$(awk '$1=="RESULT"{print $2; exit}' \
  "$C5/09-verification/final.tsv")"

CELL6_RESULT="$(awk '$1=="RESULT"{print $2; exit}' \
  "$C6/05-verification/result.tsv")"

echo "CELL5_RESULT=$CELL5_RESULT"
echo "CELL6_RESULT=$CELL6_RESULT"

if [[ "$CELL5_RESULT" == "CELL_5_PASS" &&
      "$CELL6_RESULT" == "CELL_6_PASS" ]]; then
  echo 'PRECONDITION=PASS'
else
  echo 'PRECONDITION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[2] SAFETY'

cat > "$OUT/01-input/safety.tsv" <<EOF
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
echo '[3] INPUT'

cp -f "$C6/02-evidence/evidence.tsv" \
  "$OUT/01-input/cell6-evidence.tsv"

cp -f "$C4/02-mapping/unassigned.tsv" \
  "$OUT/01-input/unassigned.tsv"

GAP_COUNT="$(wc -l < "$C4/02-mapping/unassigned.tsv")"

echo "GAP_COUNT=$GAP_COUNT"

if (( GAP_COUNT == 8 )); then
  echo 'INPUT=PASS'
else
  echo 'INPUT=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[4] MOLECULE BASELINE'

awk -F'\t' '
{
  count[$2]++
}
END {
  for (m in count)
    print m "\t" count[m]
}' "$C4/02-mapping/key-to-molecule.tsv" |
sort > "$OUT/02-correlation/molecule-baseline.tsv"

cat "$OUT/02-correlation/molecule-baseline.tsv"

echo
echo '[5] CORRELATION'

echo 'resource	molecule_hint	type	confidence	filename_match	pool_match	relation_match	correlation	evidence	decision	reason' \
> "$OUT/03-evidence/correlation.tsv"

tail -n +2 "$C6/02-evidence/evidence.tsv" |
while IFS=$'\t' read -r resource hint type confidence decision reason
do

  [[ -n "$resource" ]] || continue

  filename="${resource#*--}"

  filename_match=0
  pool_match=0
  relation_match=0

  case "$filename" in
    *.patch|*.patch.*)
      [[ "$hint" == "M0001" ]] && filename_match=1
      ;;
    *.sh|*.zsh|*.py|*.c|*.h|*CMakeLists.txt|Makefile|makefile)
      [[ "$hint" == "M0003" ]] && filename_match=1
      ;;
    *.xml|*.json|*.toml|*.ini|*.cfg|*.conf)
      [[ "$hint" == "M0002" ]] && filename_match=1
      ;;
    *.md|*.txt)
      [[ "$hint" == "M0004" ]] && filename_match=1
      ;;
  esac

  pool="$(
    awk -F'\t' -v r="$resource" '$1==r{print $4; exit}' \
      "$C4/02-mapping/resource-map.raw"
  )"

  case "$hint:$pool" in
    M0001:*patch*) pool_match=1 ;;
    M0003:*capability*) pool_match=1 ;;
    M0002:*data*) pool_match=1 ;;
    M0004:*knowledge*) pool_match=1 ;;
  esac

  relation_match="$(
    awk -F'\t' -v r="$resource" '$7==r{print 1; exit}' \
      "$C4/03-relations/relation-map.tsv"
  )"

  [[ "$relation_match" == "1" ]] || relation_match=0

  correlation=$((filename_match + pool_match + relation_match))

  if (( correlation >= 3 )); then
    evidence='STRONG'
    final_decision='MAP_PROPOSAL'
    final_reason='MULTI_SIGNAL_CORRELATION'
  elif (( correlation == 2 )); then
    evidence='MEDIUM'
    final_decision='HOLD_REVIEW'
    final_reason='PARTIAL_CORRELATION'
  else
    evidence='WEAK'
    final_decision='OBSERVE'
    final_reason='INSUFFICIENT_CORRELATION'
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$resource" \
    "$hint" \
    "$type" \
    "$confidence" \
    "$filename_match" \
    "$pool_match" \
    "$relation_match" \
    "$correlation" \
    "$evidence" \
    "$final_decision" \
    "$final_reason" \
    >> "$OUT/03-evidence/correlation.tsv"

done

cat "$OUT/03-evidence/correlation.tsv"

echo
echo '[6] EVIDENCE SUMMARY'

STRONG="$(awk -F'\t' 'NR>1&&$9=="STRONG"{c++}END{print c+0}' \
  "$OUT/03-evidence/correlation.tsv")"

MEDIUM="$(awk -F'\t' 'NR>1&&$9=="MEDIUM"{c++}END{print c+0}' \
  "$OUT/03-evidence/correlation.tsv")"

WEAK="$(awk -F'\t' 'NR>1&&$9=="WEAK"{c++}END{print c+0}' \
  "$OUT/03-evidence/correlation.tsv")"

echo "STRONG=$STRONG"
echo "MEDIUM=$MEDIUM"
echo "WEAK=$WEAK"

echo
echo '[7] CONSERVATION'

CLASSIFIED=$((STRONG + MEDIUM + WEAK))

echo "INPUT=$GAP_COUNT"
echo "CLASSIFIED=$CLASSIFIED"

if (( CLASSIFIED == GAP_COUNT )); then
  echo 'CORRELATION_CONSERVATION=PASS'
else
  echo 'CORRELATION_CONSERVATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[8] PROPOSALS'

awk -F'\t' 'NR>1&&$10=="MAP_PROPOSAL"{
  print
}' "$OUT/03-evidence/correlation.tsv" \
> "$OUT/04-decisions/map-proposals.tsv"

awk -F'\t' 'NR>1&&$10=="HOLD_REVIEW"{
  print
}' "$OUT/03-evidence/correlation.tsv" \
> "$OUT/04-decisions/hold-review.tsv"

awk -F'\t' 'NR>1&&$10=="OBSERVE"{
  print
}' "$OUT/03-evidence/correlation.tsv" \
> "$OUT/04-decisions/observe.tsv"

echo "MAP_PROPOSALS=$(wc -l < "$OUT/04-decisions/map-proposals.tsv")"
echo "HOLD_REVIEW=$(wc -l < "$OUT/04-decisions/hold-review.tsv")"
echo "OBSERVE=$(wc -l < "$OUT/04-decisions/observe.tsv")"

echo
echo '[9] SOURCE PRESERVATION'

echo 'SOURCE_MODIFY=NO'
echo 'SOURCE_DELETE=NO'
echo 'SOURCE_MOVE=NO'
echo 'SOURCE_RENAME=NO'
echo 'SOURCE_QUARANTINE=NO'
echo 'MEMBERSHIP_MODIFY=NO'
echo 'DNA_MUTATION=NO'

MEMBERSHIP_COUNT="$(wc -l < \
  "$C4/02-mapping/key-to-molecule.tsv")"

echo "CELL4_MEMBERSHIP=$MEMBERSHIP_COUNT"

if (( MEMBERSHIP_COUNT == 992 )); then
  echo 'CELL4_MEMBERSHIP=UNCHANGED'
else
  echo 'CELL4_MEMBERSHIP=CHANGED'
  FAIL=$((FAIL+1))
fi

echo
echo '[10] FINAL GATE'

if (( FAIL == 0 )); then
  FINAL='CELL_7_PASS'
else
  FINAL='CELL_7_FAIL'
fi

cat > "$OUT/05-verification/result.tsv" <<EOF
RESULT	$FINAL
CELL5_RESULT	$CELL5_RESULT
CELL6_RESULT	$CELL6_RESULT
INPUT_GAPS	$GAP_COUNT
CLASSIFIED	$CLASSIFIED
STRONG	$STRONG
MEDIUM	$MEDIUM
WEAK	$WEAK
MAP_PROPOSALS	$(wc -l < "$OUT/04-decisions/map-proposals.tsv")
HOLD_REVIEW	$(wc -l < "$OUT/04-decisions/hold-review.tsv")
OBSERVE	$(wc -l < "$OUT/04-decisions/observe.tsv")
MEMBERSHIP_MODIFY	NO
SOURCE_DATA	INTACT
DNA	UNCHANGED
LINEAGE	PRESERVED
RIGHTS	INHERITED_ONLY
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
EOF

echo "RESULT=$FINAL"
echo "FAIL_COUNT=$FAIL"

echo
echo '============================================================'

if [[ "$FINAL" == "CELL_7_PASS" ]]; then
  echo ' CELL 7 COMPLETE'
  echo ' RESULT=CELL_7_PASS'
  echo " CHECKPOINT=$OUT"
  echo ' SOURCE_DATA=INTACT'
  echo ' CELL4_DATA=UNCHANGED'
  echo ' CELL5_DATA=UNCHANGED'
  echo ' CELL6_DATA=UNCHANGED'
  echo ' DNA=UNCHANGED'
  echo ' MEMBERSHIP_MODIFY=NO'
  echo ' NEXT=CELL_8'
else
  echo ' CELL 7 INCOMPLETE'
  echo ' RESULT=CELL_7_FAIL'
  echo " CHECKPOINT=$OUT"
  echo ' NEXT=REVIEW'
fi

echo '============================================================'
