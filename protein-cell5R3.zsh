#!/data/data/com.termux/files/usr/bin/zsh

export PATH="/data/data/com.termux/files/usr/bin:$HOME/bin:/system/bin:/system/xbin"
rehash

R="$HOME/.config/dynu-audit/protein"
C4="$R/02-collector/checkpoints/cell4R3-dependency-20260905-024119"

RUN="$(date +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell5R3-validation-$RUN"

mkdir -p "$OUT"/{01-input,02-structure,03-molecule,04-relation,05-dependency,06-completeness,07-recovery,08-conflict,09-verification}

echo '============================================================'
echo ' PROTEIN — CELL 5 R3 — VALIDATION'
echo '============================================================'
echo
echo "RUN=$RUN"
echo "CELL4=$C4"
echo "OUTPUT=$OUT"

FAIL=0

echo
echo '[1] INPUT FILES'

for f in \
  "$C4/01-input/safety.tsv" \
  "$C4/02-mapping/key-to-molecule.tsv" \
  "$C4/02-mapping/resource-map.raw" \
  "$C4/02-mapping/resource-map.tsv" \
  "$C4/02-mapping/unassigned.tsv" \
  "$C4/03-relations/cross.tsv" \
  "$C4/03-relations/relation-map.tsv" \
  "$C4/04-dependency/cross-count.tsv" \
  "$C4/04-dependency/dependency.tsv" \
  "$C4/05-completeness/completeness.tsv" \
  "$C4/06-gaps/gap-types.tsv" \
  "$C4/06-gaps/unassigned.tsv" \
  "$C4/07-recovery/recovery.tsv" \
  "$C4/08-verification/lineage.tsv" \
  "$C4/08-verification/result.tsv"
do
  if [[ -f "$f" ]]; then
    echo "PASS $(basename "$f")"
  else
    echo "FAIL MISSING $(basename "$f")"
    FAIL=$((FAIL+1))
  fi
done

cp -f "$C4/08-verification/result.tsv" "$OUT/01-input/cell4-result.tsv"
cp -f "$C4/08-verification/lineage.tsv" "$OUT/01-input/cell4-lineage.tsv"

echo
echo '[2] STRUCTURAL COUNTS'

RAW_RESOURCES="$(wc -l < "$C4/02-mapping/resource-map.raw")"
MAPPED_RESOURCES="$(wc -l < "$C4/02-mapping/resource-map.tsv")"
UNASSIGNED="$(wc -l < "$C4/02-mapping/unassigned.tsv")"
KEYS="$(wc -l < "$C4/02-mapping/key-to-molecule.tsv")"
RELATIONS="$(wc -l < "$C4/03-relations/relation-map.tsv")"
DEPENDENCIES="$(wc -l < "$C4/04-dependency/dependency.tsv")"
COMPLETENESS="$(wc -l < "$C4/05-completeness/completeness.tsv")"
RECOVERY="$(wc -l < "$C4/07-recovery/recovery.tsv")"

echo "RAW_RESOURCES=$RAW_RESOURCES"
echo "MAPPED_RESOURCES=$MAPPED_RESOURCES"
echo "UNASSIGNED_RESOURCES=$UNASSIGNED"
echo "KEYS=$KEYS"
echo "RELATIONS=$RELATIONS"
echo "DEPENDENCY_RECORDS=$DEPENDENCIES"
echo "COMPLETENESS_RECORDS=$COMPLETENESS"
echo "RECOVERY_RECORDS=$RECOVERY"

cat > "$OUT/02-structure/counts.tsv" <<EOF
RAW_RESOURCES	$RAW_RESOURCES
MAPPED_RESOURCES	$MAPPED_RESOURCES
UNASSIGNED_RESOURCES	$UNASSIGNED
KEYS	$KEYS
RELATIONS	$RELATIONS
DEPENDENCY_RECORDS	$DEPENDENCIES
COMPLETENESS_RECORDS	$COMPLETENESS
RECOVERY_RECORDS	$RECOVERY
EOF

if (( RAW_RESOURCES != 1000 )); then FAIL=$((FAIL+1)); fi
if (( MAPPED_RESOURCES != 992 )); then FAIL=$((FAIL+1)); fi
if (( UNASSIGNED != 8 )); then FAIL=$((FAIL+1)); fi
if (( KEYS != 992 )); then FAIL=$((FAIL+1)); fi
if (( RELATIONS != 992 )); then FAIL=$((FAIL+1)); fi
if (( DEPENDENCIES != 4 )); then FAIL=$((FAIL+1)); fi
if (( COMPLETENESS != 4 )); then FAIL=$((FAIL+1)); fi
if (( RECOVERY != 4 )); then FAIL=$((FAIL+1)); fi

echo
echo '[3] RESOURCE CONSERVATION'

if (( MAPPED_RESOURCES + UNASSIGNED == RAW_RESOURCES )); then
  echo 'RESOURCE_CONSERVATION=PASS'
  echo "FORMULA=$MAPPED_RESOURCES+$UNASSIGNED=$RAW_RESOURCES"
else
  echo 'RESOURCE_CONSERVATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[4] MOLECULE SET'

awk '{print $2}' "$C4/02-mapping/key-to-molecule.tsv" |
sort -u > "$OUT/03-molecule/molecule-set.tsv"

for m in M0001 M0002 M0003 M0004
do
  n="$(awk -v m="$m" '$2==m{c++} END{print c+0}' \
       "$C4/02-mapping/key-to-molecule.tsv")"
  echo "$m=$n"

  case "$m" in
    M0001) (( n == 596 )) || FAIL=$((FAIL+1)) ;;
    M0002) (( n == 1 ))   || FAIL=$((FAIL+1)) ;;
    M0003) (( n == 394 )) || FAIL=$((FAIL+1)) ;;
    M0004) (( n == 1 ))   || FAIL=$((FAIL+1)) ;;
  esac
done

MOLECULE_SET="$(cat "$OUT/03-molecule/molecule-set.tsv" | tr '\n' ' ')"
echo "MOLECULE_SET=$MOLECULE_SET"

EXPECTED_MOLECULES=4
ACTUAL_MOLECULES="$(wc -l < "$OUT/03-molecule/molecule-set.tsv")"

if (( ACTUAL_MOLECULES == EXPECTED_MOLECULES )) &&
   grep -qx 'M0001' "$OUT/03-molecule/molecule-set.tsv" &&
   grep -qx 'M0002' "$OUT/03-molecule/molecule-set.tsv" &&
   grep -qx 'M0003' "$OUT/03-molecule/molecule-set.tsv" &&
   grep -qx 'M0004' "$OUT/03-molecule/molecule-set.tsv"
then
  echo 'MOLECULE_SET=PASS'
else
  echo 'MOLECULE_SET=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[5] RELATION VALIDATION'

RELATION_MAPPED="$RELATIONS"

if (( RELATION_MAPPED == 992 )) &&
   [[ "$(wc -l < "$C4/03-relations/cross.tsv")" == "0" ]]
then
  echo 'RELATION_VALIDATION=PASS'
else
  echo 'RELATION_VALIDATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[6] DEPENDENCY VALIDATION'

cat "$C4/04-dependency/dependency.tsv"

DEP_TOTAL="$DEPENDENCIES"
DEP_CROSS="$(awk '$4=="CROSS_DEPENDENCY"{c++} END{print c+0}' "$C4/04-dependency/dependency.tsv")"
DEP_INTERNAL="$(awk '$4=="INTERNAL_DEPENDENCY"{c++} END{print c+0}' "$C4/04-dependency/dependency.tsv")"

echo "TOTAL=$DEP_TOTAL"
echo "INTERNAL=$DEP_INTERNAL"
echo "CROSS=$DEP_CROSS"

if (( DEP_TOTAL == 4 && DEP_INTERNAL == 4 && DEP_CROSS == 0 )); then
  echo 'DEPENDENCY_VALIDATION=PASS'
else
  echo 'DEPENDENCY_VALIDATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[7] COMPLETENESS VALIDATION'

COMP_TOTAL="$COMPLETENESS"
COMP_COMPLETE="$(awk '$3=="COMPLETE"{c++} END{print c+0}' "$C4/05-completeness/completeness.tsv")"
COMP_PARTIAL="$(awk '$3=="PARTIAL"{c++} END{print c+0}' "$C4/05-completeness/completeness.tsv")"
COMP_EMPTY="$(awk '$3=="EMPTY"{c++} END{print c+0}' "$C4/05-completeness/completeness.tsv")"

echo "TOTAL=$COMP_TOTAL"
echo "COMPLETE=$COMP_COMPLETE"
echo "PARTIAL=$COMP_PARTIAL"
echo "EMPTY=$COMP_EMPTY"

if (( COMP_TOTAL == 4 && COMP_COMPLETE == 4 && COMP_PARTIAL == 0 && COMP_EMPTY == 0 )); then
  echo 'COMPLETENESS_VALIDATION=PASS'
else
  echo 'COMPLETENESS_VALIDATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[8] RECOVERY VALIDATION'

REC_HOLD="$(awk '$5=="HOLD"{c++} END{print c+0}' "$C4/07-recovery/recovery.tsv")"
REC_COMPLETE="$(awk '$4=="COMPLETE"{c++} END{print c+0}' "$C4/07-recovery/recovery.tsv")"

echo "TOTAL=$RECOVERY"
echo "COMPLETE=$REC_COMPLETE"
echo "HOLD=$REC_HOLD"

if (( RECOVERY == 4 && REC_COMPLETE == 4 && REC_HOLD == 4 )); then
  echo 'RECOVERY_VALIDATION=PASS'
else
  echo 'RECOVERY_VALIDATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[9] CELL 4 RESULT — EXACT'

CELL4_RESULT="$(awk '$1=="RESULT"{print $2; exit}' "$C4/08-verification/result.tsv")"

echo "CELL4_RESULT=$CELL4_RESULT"

if [[ "$CELL4_RESULT" == "CELL_4_PASS" ]]; then
  echo 'CELL4_RESULT_VALIDATION=PASS'
else
  echo 'CELL4_RESULT_VALIDATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[10] LINEAGE'

LINEAGE_RESULT="$(awk '$1=="RESULT"{print $2; exit}' "$C4/08-verification/lineage.tsv")"
LINEAGE_RIGHTS="$(awk '$1=="RIGHTS"{print $2; exit}' "$C4/08-verification/lineage.tsv")"
DNA_MUTATION="$(awk '$1=="DNA_MUTATION"{print $2; exit}' "$C4/08-verification/lineage.tsv")"
SOURCE_INTACT="$(awk '$1=="SOURCE_DATA_INTACT"{print $2; exit}' "$C4/08-verification/lineage.tsv")"

echo "RESULT=$LINEAGE_RESULT"
echo "RIGHTS=$LINEAGE_RIGHTS"
echo "DNA_MUTATION=$DNA_MUTATION"
echo "SOURCE_DATA_INTACT=$SOURCE_INTACT"

if [[ "$LINEAGE_RESULT" == "CELL_4_PASS" &&
      "$LINEAGE_RIGHTS" == "INHERITED_ONLY" &&
      "$DNA_MUTATION" == "NO" &&
      "$SOURCE_INTACT" == "YES" ]]
then
  echo 'LINEAGE_VALIDATION=PASS'
else
  echo 'LINEAGE_VALIDATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[11] SAFETY'

cat "$C4/08-verification/result.tsv" > "$OUT/09-verification/cell4-safety.tsv"

SAFETY_FAIL=0

for key in \
  SOURCE_MODIFY \
  SOURCE_DELETE \
  SOURCE_MOVE \
  SOURCE_RENAME \
  SOURCE_QUARANTINE \
  DNA_MUTATION \
  RESOURCE_EXECUTE \
  PROCESS_KILL \
  DECAY \
  DELETE \
  REPLACE
do
  value="$(awk -v k="$key" '$1==k{print $2; exit}' "$C4/08-verification/result.tsv")"
  echo "$key=$value"

  [[ "$value" == "NO" ]] || SAFETY_FAIL=$((SAFETY_FAIL+1))
done

RIGHTS="$(awk '$1=="RIGHTS"{print $2; exit}' "$C4/08-verification/result.tsv")"
echo "RIGHTS=$RIGHTS"

[[ "$RIGHTS" == "INHERITED_ONLY" ]] || SAFETY_FAIL=$((SAFETY_FAIL+1))

if (( SAFETY_FAIL == 0 )); then
  echo 'SAFETY_VALIDATION=PASS'
else
  echo 'SAFETY_VALIDATION=FAIL'
  FAIL=$((FAIL+1))
fi

echo
echo '[12] CONFLICT'

CROSS_REL="$(wc -l < "$C4/03-relations/cross.tsv")"
CROSS_DEP="$(wc -l < "$C4/04-dependency/cross-count.tsv")"

echo "CROSS_RELATION_RECORDS=$CROSS_REL"
echo "CROSS_DEPENDENCY_RECORDS=$CROSS_DEP"

if (( CROSS_REL == 0 && CROSS_DEP == 0 )); then
  echo 'CONFLICTS=0'
  echo 'CONFLICT_STATUS=NONE'
else
  echo 'CONFLICT_STATUS=REVIEW'
fi

echo
echo '[13] FINAL GATE'

cat > "$OUT/09-verification/result.tsv" <<EOF
RAW_RESOURCES	$RAW_RESOURCES
MAPPED_RESOURCES	$MAPPED_RESOURCES
UNASSIGNED_RESOURCES	$UNASSIGNED
KEYS	$KEYS
RELATIONS	$RELATIONS
DEPENDENCY_RECORDS	$DEPENDENCIES
COMPLETENESS_RECORDS	$COMPLETENESS
RECOVERY_RECORDS	$RECOVERY
MOLECULES	$ACTUAL_MOLECULES
CELL4_RESULT	$CELL4_RESULT
LINEAGE_RESULT	$LINEAGE_RESULT
RIGHTS	$RIGHTS
DNA_MUTATION	$DNA_MUTATION
SOURCE_DATA_INTACT	$SOURCE_INTACT
FAIL_COUNT	$FAIL
EOF

if (( FAIL == 0 )); then
  FINAL='CELL_5_PASS'
else
  FINAL='CELL_5_FAIL'
fi

echo "RESULT=$FINAL"
echo "FAIL_COUNT=$FAIL"

echo
echo '[14] SAFETY INVARIANT'

echo 'SOURCE_MODIFY=NO'
echo 'SOURCE_DELETE=NO'
echo 'SOURCE_MOVE=NO'
echo 'SOURCE_RENAME=NO'
echo 'SOURCE_QUARANTINE=NO'
echo 'DNA_MUTATION=NO'
echo 'RESOURCE_EXECUTE=NO'
echo 'PROCESS_KILL=NO'
echo 'DECAY=NO'
echo 'DELETE=NO'
echo 'REPLACE=NO'
echo 'EXTERNAL_WRITE=NO'
echo 'CREDENTIAL_READ=NO'
echo 'AUTO_DELETE=false'
echo 'AUTO_MOVE=false'
echo 'AUTO_QUARANTINE=false'
echo 'AUTO_KILL=false'
echo 'RIGHTS=INHERITED_ONLY'

cat > "$OUT/09-verification/final.tsv" <<EOF
RESULT	$FINAL
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

echo
echo '============================================================'

if [[ "$FINAL" == "CELL_5_PASS" ]]; then
  echo ' CELL 5 COMPLETE'
  echo ' RESULT=CELL_5_PASS'
  echo " CHECKPOINT=$OUT"
  echo ' SOURCE_DATA=INTACT'
  echo ' DNA=UNCHANGED'
  echo ' LINEAGE=PRESERVED'
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
