#!/usr/bin/env zsh

set -u

ROOT="$HOME/.config/dynu-audit"
P="$ROOT/protein"

RELATION="$P/04-relation/protein-relation.state"
FOLD_STATE="$P/12-runtime/state/folding.state"
FOLD_RESULT="$P/12-runtime/state/folding.result"
MOL_STATE="$P/12-runtime/state/molecule.state"
LIVE_MOL="$P/11-molecules/live.molecule"
MAP="$P/00-core/map"

ok=0
fail=0

check() {
  if [[ "$1" == "OK" ]]; then
    printf '[OK]   %s\n' "$2"
    (( ok++ )) || true
  else
    printf '[FAIL] %s\n' "$2"
    (( fail++ )) || true
  fi
}

printf '%s\n' '=== PROTEIN VALIDATOR ==='
printf 'ROOT: %s\n' "$ROOT"

[[ -f "$RELATION" ]] && check OK relation || check FAIL relation

if [[ -f "$FOLD_STATE" && -f "$FOLD_RESULT" ]]; then
  fold_status=$(awk -F= '$1=="STATUS"{print $2}' "$FOLD_STATE")
  result=$(awk -F= '$1=="FOLDING_RESULT"{print $2}' "$FOLD_RESULT")
  ts1=$(awk -F= '$1=="TIMESTAMP"{print $2}' "$FOLD_STATE")
  ts2=$(awk -F= '$1=="TIMESTAMP"{print $2}' "$FOLD_RESULT")

  [[ "$fold_status" == "FOLDED" ]] &&
  [[ "$result" == "OK" ]] &&
  [[ "$ts1" == "$ts2" ]] &&
  check OK folding ||
  check FAIL folding
else
  check FAIL folding
fi

if [[ -f "$MOL_STATE" && -f "$LIVE_MOL" ]]; then
  beads1=$(awk -F= '$1=="BEADS"{print $2}' "$MOL_STATE")
  beads2=$(awk -F= '$1=="BEADS"{print $2}' "$LIVE_MOL")
  last1=$(awk -F= '$1=="LAST_BEAD"{print $2}' "$MOL_STATE")
  last2=$(awk -F= '$1=="LAST_BEAD"{print $2}' "$LIVE_MOL")

  [[ "$beads1" == "$beads2" ]] &&
  [[ "$last1" == "$last2" ]] &&
  check OK molecule ||
  check FAIL molecule
else
  check FAIL molecule
fi

broken=0
while IFS= read -r link; do
  [[ -e "$link" ]] || (( broken++ ))
done < <(find "$MAP" -mindepth 1 -maxdepth 1 -type l 2>/dev/null)

(( broken == 0 )) &&
  check OK map ||
  check FAIL map

if (( fail == 0 )); then
  printf '\nRESULT=VALID\n'
else
  printf '\nRESULT=INVALID\n'
fi

printf 'CHECKS=%d FAILURES=%d\n' "$ok" "$fail"
printf '%s\n' 'READ-ONLY'
