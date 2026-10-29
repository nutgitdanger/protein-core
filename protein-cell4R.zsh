#!/usr/bin/env zsh
setopt NO_NOMATCH
setopt NULL_GLOB

export PATH="$PREFIX/bin:$HOME/bin:$HOME/.config/zsh/functions:/system/bin:/system/xbin"

R="${PROTEIN_ROOT:-$HOME/.config/dynu-audit/protein}"
CELL3="$R/02-collector/checkpoints/cell3-molecule-20260905-020636"

RUN="$(date +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell4R-dependency-$RUN"

mkdir -p \
  "$OUT/01-input" \
  "$OUT/02-mapping" \
  "$OUT/03-relations" \
  "$OUT/04-dependency" \
  "$OUT/05-completeness" \
  "$OUT/06-gaps" \
  "$OUT/07-recovery" \
  "$OUT/08-verification"

MOL="$CELL3/molecules/molecules.tsv"
MEM="$CELL3/molecules/membership.tsv"
REL="$CELL3/relations/relations.tsv"
RES="$CELL3/input/resources.tsv"

echo '============================================================'
echo ' PROTEIN V2 — CELL 4R'
echo ' DEPENDENCY / RELATION / COMPLETENESS / RECOVERY'
echo '============================================================'
echo "RUN=$RUN"
echo "CELL3=$CELL3"
echo "OUTPUT=$OUT"
echo

# ------------------------------------------------------------
# SAFETY
# ------------------------------------------------------------

cat > "$OUT/01-input/safety.tsv" <<'SAFE'
MODE	CELL4R_DEPENDENCY_ANALYSIS
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

echo '[SAFETY]'
cat "$OUT/01-input/safety.tsv"
echo

# ------------------------------------------------------------
# CORE 1 — INPUT / INTEGRITY
# ------------------------------------------------------------

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

MOL_COUNT=$(wc -l < "$MOL")
MEM_COUNT=$(wc -l < "$MEM")
REL_COUNT=$(wc -l < "$REL")
RES_COUNT=$(wc -l < "$RES")

cat > "$OUT/01-input/counts.tsv" <<EOF2
RESOURCES	$RES_COUNT
MEMBERSHIP	$MEM_COUNT
MOLECULES	$MOL_COUNT
RELATIONS	$REL_COUNT
EOF2

echo "RESOURCES=$RES_COUNT"
echo "MEMBERSHIP=$MEM_COUNT"
echo "MOLECULES=$MOL_COUNT"
echo "RELATIONS=$REL_COUNT"
echo

# ------------------------------------------------------------
# CORE 2 — RESOURCE → MOLECULE MAPPING
# IMPORTANT:
# Cell 3 TSV is HEADERLESS.
# membership schema:
# molecule status group fiber ext filename size depth path
# resource schema:
# hash ... filename ...
# ------------------------------------------------------------

echo '[CORE 2] RESOURCE → MOLECULE MAPPING'

awk -F '\t' '
{
  molecule=$1
  filename=$6
  if (molecule != "" && filename != "")
    map[filename]=molecule
}
END {
  for (f in map)
    print map[f] "\t" f
}
' "$MEM" | sort > "$OUT/02-mapping/filename-to-molecule.tsv"

MAPPED=0
UNASSIGNED=0

: > "$OUT/02-mapping/resource-map.tsv"
: > "$OUT/02-mapping/unassigned.tsv"

while IFS=$'\t' read -r hash path rest
do
  [[ -z "$hash" ]] && continue

  filename="${path:t}"

  molecule=$(awk -F '\t' -v f="$filename" '$2==f {print $1; exit}' \
    "$OUT/02-mapping/filename-to-molecule.tsv")

  if [[ -n "$molecule" ]]; then
    print -r -- "$molecule\t$hash\t$filename\t$path" \
      >> "$OUT/02-mapping/resource-map.tsv"
    (( MAPPED++ ))
  else
    print -r -- "$hash\t$filename\t$path" \
      >> "$OUT/02-mapping/unassigned.tsv"
    (( UNASSIGNED++ ))
  fi
done < "$RES"

echo "RESOURCE_COUNT=$RES_COUNT"
echo "MEMBERSHIP_COUNT=$MEM_COUNT"
echo "MAPPED_RESOURCES=$MAPPED"
echo "UNASSIGNED_RESOURCES=$UNASSIGNED"
echo

# ------------------------------------------------------------
# CORE 3 — RELATION ANALYSIS
# relations schema:
# source-group target-group fiber ext filename size depth path
# filename = field 5
# ------------------------------------------------------------

echo '[CORE 3] RELATION ANALYSIS'

: > "$OUT/03-relations/relation-map.tsv"
: > "$OUT/03-relations/cross.tsv"

REL_MAPPED=0
REL_CROSS=0

while IFS=$'\t' read -r source target fiber ext filename size depth path
do
  [[ -z "$filename" ]] && continue

  molecule=$(awk -F '\t' -v f="$filename" '$2==f {print $1; exit}' \
    "$OUT/02-mapping/filename-to-molecule.tsv")

  if [[ -n "$molecule" ]]; then
    print -r -- "$molecule\t$source\t$target\t$fiber\t$ext\t$filename\t$size\t$depth\t$path" \
      >> "$OUT/03-relations/relation-map.tsv"
    (( REL_MAPPED++ ))

    if [[ "$source" != "$target" ]]; then
      print -r -- "$molecule\t$source\t$target\tCROSS" \
        >> "$OUT/03-relations/cross.tsv"
      (( REL_CROSS++ ))
    fi
  fi
done < "$REL"

echo "RELATIONS_INPUT=$REL_COUNT"
echo "RELATIONS_MAPPED=$REL_MAPPED"
echo "CROSS_RELATIONS=$REL_CROSS"
echo

# ------------------------------------------------------------
# CORE 4 — DEPENDENCY
# ------------------------------------------------------------

echo '[CORE 4] DEPENDENCY'

: > "$OUT/04-dependency/dependency.tsv"

while IFS=$'\t' read -r molecule
do
  [[ -z "$molecule" ]] && continue

  internal=$(awk -F '\t' -v m="$molecule" '$1==m {c++} END{print c+0}' \
    "$OUT/03-relations/relation-map.tsv")

  cross=$(awk -F '\t' -v m="$molecule" '$1==m {c++} END{print c+0}' \
    "$OUT/03-relations/cross.tsv")

  if (( cross > 0 )); then
    dep="CROSS_DEPENDENCY"
  elif (( internal > 0 )); then
    dep="INTERNAL_DEPENDENCY"
  else
    dep="NO_RELATION"
  fi

  print -r -- "$molecule\t$internal\t$cross\t$dep" \
    >> "$OUT/04-dependency/dependency.tsv"

done < <(cut -f1 "$MOL")

DEPENDENCY_COUNT=$(wc -l < "$OUT/04-dependency/dependency.tsv")
CONNECTED=$(awk -F '\t' '$4=="CROSS_DEPENDENCY"{c++} END{print c+0}' "$OUT/04-dependency/dependency.tsv")
INTERNAL=$(awk -F '\t' '$4=="INTERNAL_DEPENDENCY"{c++} END{print c+0}' "$OUT/04-dependency/dependency.tsv")
NO_REL=$(awk -F '\t' '$4=="NO_RELATION"{c++} END{print c+0}' "$OUT/04-dependency/dependency.tsv")

echo "DEPENDENCY_RECORDS=$DEPENDENCY_COUNT"
echo "CROSS_DEPENDENCY=$CONNECTED"
echo "INTERNAL_DEPENDENCY=$INTERNAL"
echo "NO_RELATION=$NO_REL"
echo

# ------------------------------------------------------------
# CORE 5 — COMPLETENESS
# ------------------------------------------------------------

echo '[CORE 5] COMPLETENESS'

: > "$OUT/05-completeness/completeness.tsv"

while IFS=$'\t' read -r molecule
do
  [[ -z "$molecule" ]] && continue

  assigned=$(awk -F '\t' -v m="$molecule" '$1==m {c++} END{print c+0}' \
    "$OUT/02-mapping/resource-map.tsv")

  relation=$(awk -F '\t' -v m="$molecule" '$1==m {c++} END{print c+0}' \
    "$OUT/03-relations/relation-map.tsv")

  if (( assigned > 0 && relation > 0 )); then
    status="COMPLETE"
  elif (( assigned > 0 )); then
    status="PARTIAL"
  else
    status="EMPTY"
  fi

  print -r -- "$molecule\t$assigned\t$relation\t$status" \
    >> "$OUT/05-completeness/completeness.tsv"

done < <(cut -f1 "$MOL")

COMPLETE=$(awk -F '\t' '$4=="COMPLETE"{c++} END{print c+0}' "$OUT/05-completeness/completeness.tsv")
PARTIAL=$(awk -F '\t' '$4=="PARTIAL"{c++} END{print c+0}' "$OUT/05-completeness/completeness.tsv")
EMPTY=$(awk -F '\t' '$4=="EMPTY"{c++} END{print c+0}' "$OUT/05-completeness/completeness.tsv")
COMPLETENESS_COUNT=$(wc -l < "$OUT/05-completeness/completeness.tsv")

echo "COMPLETE=$COMPLETE"
echo "PARTIAL=$PARTIAL"
echo "EMPTY=$EMPTY"
echo "COMPLETENESS_RECORDS=$COMPLETENESS_COUNT"
echo

# ------------------------------------------------------------
# CORE 6 — GAP / ORPHAN
# ------------------------------------------------------------

echo '[CORE 6] GAP / ORPHAN'

cp "$OUT/02-mapping/unassigned.tsv" \
   "$OUT/06-gaps/unassigned.tsv"

UNASSIGNED_COUNT=$(wc -l < "$OUT/06-gaps/unassigned.tsv")

awk -F '\t' '
{
  ext=$2
  if (ext=="") ext="NO_EXTENSION"
  count[ext]++
}
END {
  for (x in count)
    print x "\t" count[x]
}
' "$OUT/06-gaps/unassigned.tsv" | sort > "$OUT/06-gaps/gap-types.tsv"

GAP_TYPES=$(wc -l < "$OUT/06-gaps/gap-types.tsv")

echo "UNASSIGNED_RESOURCES=$UNASSIGNED_COUNT"
echo "GAP_TYPES=$GAP_TYPES"
echo

# ------------------------------------------------------------
# CORE 7 — RECOVERY / INSTINCT
# ------------------------------------------------------------

echo '[CORE 7] RECOVERY / INSTINCT'

: > "$OUT/07-recovery/recovery.tsv"

while IFS=$'\t' read -r molecule assigned relation status
do
  [[ -z "$molecule" ]] && continue

  if (( assigned == 0 )); then
    instinct="OBSERVE"
    reason="NO_RESOURCE_ASSIGNMENT"
  elif (( relation == 0 )); then
    instinct="DIVE"
    reason="NO_RELATION_EVIDENCE"
  elif [[ "$status" == "PARTIAL" ]]; then
    instinct="HOLD"
    reason="PARTIAL_COMPLETENESS"
  else
    instinct="HOLD"
    reason="STABLE_COMPOSITION"
  fi

  print -r -- "$molecule\t$assigned\t$relation\t$status\t$instinct\t$reason" \
    >> "$OUT/07-recovery/recovery.tsv"

done < "$OUT/05-completeness/completeness.tsv"

RECOVERY_COUNT=$(wc -l < "$OUT/07-recovery/recovery.tsv")
INSTINCT_DIVE=$(awk -F '\t' '$5=="DIVE"{c++} END{print c+0}' "$OUT/07-recovery/recovery.tsv")
INSTINCT_HOLD=$(awk -F '\t' '$5=="HOLD"{c++} END{print c+0}' "$OUT/07-recovery/recovery.tsv")
INSTINCT_OBSERVE=$(awk -F '\t' '$5=="OBSERVE"{c++} END{print c+0}' "$OUT/07-recovery/recovery.tsv")

echo "RECOVERY_RECORDS=$RECOVERY_COUNT"
echo "INSTINCT_DIVE=$INSTINCT_DIVE"
echo "INSTINCT_HOLD=$INSTINCT_HOLD"
echo "INSTINCT_OBSERVE=$INSTINCT_OBSERVE"
echo

# ------------------------------------------------------------
# CORE 8 — VERIFICATION / GATE
# ------------------------------------------------------------

echo '[CORE 8] VERIFICATION / GATE'

FAIL=0

[[ "$RES_COUNT" == "1000" ]] || FAIL=1
[[ "$MEM_COUNT" == "992" ]] || FAIL=1
[[ "$MOL_COUNT" == "4" ]] || FAIL=1
[[ "$REL_COUNT" == "1000" ]] || FAIL=1

[[ "$MAPPED" == "992" ]] || FAIL=1
[[ "$UNASSIGNED" == "8" ]] || FAIL=1
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
CELL4R_RESULT	$RESULT
RESOURCES	$RES_COUNT
MEMBERSHIP	$MEM_COUNT
MOLECULES	$MOL_COUNT
RELATIONS	$REL_COUNT
MAPPED_RESOURCES	$MAPPED
UNASSIGNED_RESOURCES	$UNASSIGNED
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

echo
cat "$OUT/08-verification/result.tsv"

# ------------------------------------------------------------
# FINAL LINEAGE
# ------------------------------------------------------------

cat > "$OUT/08-verification/lineage.tsv" <<EOF2
ROOT	DNA
PARENT	PROTEIN
GENERATION	CELL_4R
SOURCE	CELL_3
CELL3_CHECKPOINT	$CELL3
RESULT	$RESULT
RIGHTS	INHERITED_ONLY
DNA_MUTATION	NO
SOURCE_DATA_INTACT	YES
DECAY	NO
DELETE	NO
REPLACE	NO
EOF2

echo
echo '============================================================'

if (( FAIL == 0 )); then
  echo ' CELL 4 COMPLETE'
  echo ' RESULT=CELL_4_PASS'
else
  echo ' CELL 4 INCOMPLETE'
  echo ' RESULT=CELL_4_FAIL'
fi

echo "CHECKPOINT=$OUT"
echo 'SOURCE_DATA=INTACT'
echo 'DNA=UNCHANGED'
echo 'LINEAGE=PRESERVED'
echo '============================================================'
