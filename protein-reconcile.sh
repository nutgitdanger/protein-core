#!/usr/bin/env zsh

ROOT="${0:A:h}"
cd "$ROOT" || exit 1

CANONICAL=(
  protein/12-runtime/state/folding.state
  protein/12-runtime/state/folding.result
  protein/12-runtime/state/molecule.state
  protein/11-molecules/live.molecule
  protein/04-relation/protein-relation.state
)

printf '%s\n' '>>> [RECONCILE] Canonical validation'

for f in $CANONICAL; do
  if [ ! -s "$f" ]; then
    printf '%s\n' "[STOP] missing or empty: $f"
    exit 1
  fi
done

get_field() {
  awk -F= -v k="$2" '$1==k {print substr($0,index($0,"=")+1); exit}' "$1"
}

F_STATE="protein/12-runtime/state/folding.state"
F_RESULT="protein/12-runtime/state/folding.result"
M_STATE="protein/12-runtime/state/molecule.state"
M_LIVE="protein/11-molecules/live.molecule"

for k in TIMESTAMP FIBERS MOLECULES STATES; do
  a=$(get_field "$F_STATE" "$k")
  b=$(get_field "$F_RESULT" "$k")
  if [ -z "$a" ] || [ "$a" != "$b" ]; then
    printf '%s\n' "[STOP] folding mismatch: $k"
    exit 1
  fi
done

if [ "$(get_field "$F_STATE" STATUS)" != "FOLDED" ]; then
  printf '%s\n' '[STOP] folding state is not FOLDED'
  exit 1
fi

if [ "$(get_field "$F_RESULT" FOLDING_RESULT)" != "OK" ]; then
  printf '%s\n' '[STOP] folding result is not OK'
  exit 1
fi

for k in BEADS LAST_BEAD TIMESTAMP; do
  a=$(get_field "$M_STATE" "$k")
  b=$(get_field "$M_LIVE" "$k")
  if [ -z "$a" ] || [ "$a" != "$b" ]; then
    printf '%s\n' "[STOP] molecule mismatch: $k"
    exit 1
  fi
done

printf '%s\n' '>>> [RECONCILE] Validation OK'

git diff --cached --quiet || { printf "%s\n" "[STOP] pre-existing staged changes"; exit 1; }

for f in $CANONICAL; do
  git add -- "$f"
done

if git diff --cached --quiet; then
  printf '%s\n' '>>> [RECONCILE] No canonical changes. Nothing committed.'
  printf "%s\n" ">>> [RECONCILE] Staging unchanged"
  exit 0
fi

STAMP=$(date +%Y%m%d_%H%M%S)
git diff --cached --check || exit 1
git diff --cached --stat

git commit -m "chore(protein): reconcile canonical runtime state $STAMP" || exit 1

AWS_DIR="runtime/ebs/protein-vault-$STAMP"
mkdir -p "$AWS_DIR/state"

for f in $CANONICAL; do
  cp -p "$f" "$AWS_DIR/state/"
done

printf '%s\n' ">>> [AWS-BRIDGE] Canonical state mirrored at $AWS_DIR"
