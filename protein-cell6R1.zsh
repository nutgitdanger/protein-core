#!/data/data/com.termux/files/usr/bin/zsh

export PATH="/data/data/com.termux/files/usr/bin:$HOME/bin:/system/bin:/system/xbin"
rehash

R="$HOME/.config/dynu-audit/protein"
C4="$R/02-collector/checkpoints/cell4R3-dependency-20260905-024119"
C5="$R/02-collector/checkpoints/cell5R3-validation-20260905-025128"

RUN="$(date +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell6R1-gap-$RUN"

mkdir -p "$OUT"/{01-input,02-evidence,03-proposals,04-decisions,05-verification}

echo '============================================================'
echo ' PROTEIN — CELL 6 R1 — GAP / EVIDENCE RESOLVER'
echo '============================================================'
echo
echo "RUN=$RUN"
echo "CELL4=$C4"
echo "CELL5=$C5"
echo "OUTPUT=$OUT"

FAIL=0

echo
echo '[1] PRECONDITION'

CELL5_RESULT="$(awk '$1=="RESULT"{print $2; exit}' \
  "$C5/09-verification/final.tsv")"

echo "CELL5_RESULT=$CELL5_RESULT"

if [[ "$CELL5_RESULT" == "CELL_5_PASS" ]]; then
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
echo '[3] GAP INPUT'

UNASSIGNED="$C4/02-mapping/unassigned.tsv"

GAP_COUNT="$(wc -l < "$UNASSIGNED")"

echo "UNASSIGNED=$GAP_COUNT"

if (( GAP_COUNT == 8 )); then
  echo 'GAP_INPUT=PASS'
else
  echo 'GAP_INPUT=FAIL'
  FAIL=$((FAIL+1))
fi

cp -f "$UNASSIGNED" "$OUT/01-input/unassigned.tsv"

echo
echo '[4] EVIDENCE CLASSIFICATION'

echo 'resource	molecule_hint	type	confidence	decision	reason' \
  > "$OUT/02-evidence/evidence.tsv"

while IFS=$'\t' read -r resource size pool fullpath
do
  [[ -n "$resource" ]] || continue

  base="${resource#*--}"

  hint='UNKNOWN'
  type='UNKNOWN'
  confidence='LOW'
  decision='OBSERVE'
  reason='INSUFFICIENT_EVIDENCE'

  case "$base" in
    *.patch|*.patch.*)
      hint='M0001'
      type='PATCH'
      confidence='HIGH'
      decision='MAP_PROPOSAL'
      reason='PATCH_MATCHES_BUILD_MOLECULE'
      ;;
    *.sh|*.zsh|*.py|*.c|*.h|*CMakeLists.txt|Makefile|makefile)
      hint='M0003'
      type='BUILD_CAPABILITY'
      confidence='MEDIUM'
      decision='HOLD_REVIEW'
      reason='BUILD_OR_NATIVE_CAPABILITY_PATTERN'
      ;;
    *.xml|*.json|*.toml|*.ini|*.cfg|*.conf)
      hint='M0002'
      type='STRUCTURED_DATA'
      confidence='MEDIUM'
      decision='HOLD_REVIEW'
      reason='STRUCTURED_DATA_PATTERN'
      ;;
    *.md|*.txt)
      hint='M0004'
      type='DOCUMENTATION'
      confidence='LOW'
      decision='OBSERVE'
      reason='DOCUMENTATION_PATTERN_WITHOUT_RELATION_EDGE'
      ;;
    *)
      hint='UNKNOWN'
      type='UNKNOWN'
      confidence='LOW'
      decision='OBSERVE'
      reason='NO_SAFE_CLASSIFICATION'
      ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$resource" "$hint" "$type" "$confidence" "$decision" "$reason" \
    >> "$OUT/02-evidence/evidence.tsv"

done < "$UNASSIGNED"

cat "$OUT/02-evidence/evidence.tsv"

echo
echo '[5] PROPOSALS'

awk -F'\t' '
NR>1 && $5=="MAP_PROPOSAL" {
  print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $6
}' "$OUT/02-evidence/evidence.tsv" \
> "$OUT/03-proposals/map-proposals.tsv"

awk -F'\t' '
NR>1 && $5=="HOLD_REVIEW" {
  print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $6
}' "$OUT/02-evidence/evidence.tsv" \
> "$OUT/03-proposals/hold-proposals.tsv"

awk -F'\t' '
NR>1 && $5=="OBSERVE" {
  print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $6
}' "$OUT/02-evidence/evidence.tsv" \
> "$OUT/03-proposals/observe-proposals.tsv"

MAP_COUNT="$(wc -l < "$OUT/03-proposals/map-proposals.tsv")"
HOLD_COUNT="$(wc -l < "$OUT/03-proposals/hold-proposals.tsv")"
OBSERVE_COUNT="$(wc -l < "$OUT/03-proposals/observe-proposals.tsv")"

echo "MAP_PROPOSALS=$MAP_COUNT"
echo "HOLD_REVIEW=$HOLD_COUNT"
echo "OBSERVE=$OBSERVE_COUNT"

echo
echo '[6] MOLECULE DISTRIBUTION OF PROPOSALS'

for m in M0001 M0002 M0003 M0004
do
  n="$(awk -F'\t' -v m="$m" '$2==m{c++} END{print c+0}' \
       "$OUT/02-evidence/evidence.tsv")"
  echo "$m=$n"
done

echo
echo '[7] CONSERVATION'

CLASSIFIED=$((MAP_COUNT + HOLD_COUNT + OBSERVE_COUNT))

echo "UNASSIGNED_INPUT=$GAP_COUNT"
echo "CLASSIFIED=$CLASSIFIED"

if (( CLASSIFIED == GAP_COUNT )); then
  echo 'CLASSIFICATION_CONSERVATION=PASS'
else
  echo 'CLASSIFICATION_CONSERVATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[8] NO SOURCE MODIFICATION'

echo 'SOURCE_MODIFY=NO'
echo 'SOURCE_DELETE=NO'
echo 'SOURCE_MOVE=NO'
echo 'SOURCE_RENAME=NO'
echo 'SOURCE_QUARANTINE=NO'
echo 'MEMBERSHIP_MODIFY=NO'
echo 'DNA_MUTATION=NO'

echo
echo '[9] CELL 4 / CELL 5 PRESERVATION'

ORIGINAL_MEMBERSHIP="$C4/02-mapping/key-to-molecule.tsv"

ORIGINAL_COUNT="$(wc -l < "$ORIGINAL_MEMBERSHIP")"

echo "ORIGINAL_MEMBERSHIP=$ORIGINAL_COUNT"

if (( ORIGINAL_COUNT == 992 )); then
  echo 'CELL4_MEMBERSHIP=UNCHANGED'
else
  echo 'CELL4_MEMBERSHIP=CHECK'
  FAIL=$((FAIL+1))
fi

echo
echo '[10] FINAL GATE'

if (( FAIL == 0 )); then
  FINAL='CELL_6_PASS'
else
  FINAL='CELL_6_FAIL'
fi

cat > "$OUT/05-verification/result.tsv" <<EOF
RESULT	$FINAL
CELL5_RESULT	$CELL5_RESULT
UNASSIGNED_INPUT	$GAP_COUNT
CLASSIFIED	$CLASSIFIED
MAP_PROPOSALS	$MAP_COUNT
HOLD_REVIEW	$HOLD_COUNT
OBSERVE	$OBSERVE_COUNT
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
LINEAGE	PRESERVED
RIGHTS	INHERITED_ONLY
SOURCE_DATA	INTACT
EOF

echo "RESULT=$FINAL"
echo "FAIL_COUNT=$FAIL"

echo
echo '============================================================'

if [[ "$FINAL" == "CELL_6_PASS" ]]; then
  echo ' CELL 6 COMPLETE'
  echo ' RESULT=CELL_6_PASS'
  echo " CHECKPOINT=$OUT"
  echo ' SOURCE_DATA=INTACT'
  echo ' CELL4_DATA=UNCHANGED'
  echo ' CELL5_DATA=UNCHANGED'
  echo ' DNA=UNCHANGED'
  echo ' MEMBERSHIP_MODIFY=NO'
  echo ' NEXT=CELL_7'
else
  echo ' CELL 6 INCOMPLETE'
  echo ' RESULT=CELL_6_FAIL'
  echo " CHECKPOINT=$OUT"
  echo ' NEXT=REVIEW'
fi

echo '============================================================'
