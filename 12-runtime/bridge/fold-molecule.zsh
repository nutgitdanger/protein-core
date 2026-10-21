#!/usr/bin/env zsh
set -u
setopt NO_NOMATCH

ROOT="$HOME/.config/dynu-audit"
P="$ROOT/protein"
S="$P/12-runtime/state"
M="$P/11-molecules"

FOLD="$S/folding.state"
RESULT="$S/folding.result"
MOLECULE="$S/molecule.state"
BEAD="$M/molecule-bead.zsh"
ENGINE="$M/molecule-engine.zsh"
MARK="$S/fold-molecule.generation"
LOCK="$S/.fold-molecule.lock"

[[ -f "$FOLD" ]] || { print "RESULT=WAIT_NO_FOLD"; exit 2; }
[[ -f "$RESULT" ]] || { print "RESULT=WAIT_NO_RESULT"; exit 2; }
[[ -f "$BEAD" ]] || { print "RESULT=ERROR_NO_BEAD_BUILDER"; exit 3; }
[[ -f "$ENGINE" ]] || { print "RESULT=ERROR_NO_MOLECULE_ENGINE"; exit 3; }

grep -q '^STATUS=FOLDED$' "$FOLD" ||
  { print "RESULT=WAIT_FOLD_NOT_COMPLETE"; exit 2; }

grep -q '^FOLDING_RESULT=OK$' "$RESULT" ||
  { print "RESULT=WAIT_FOLD_RESULT_NOT_OK"; exit 2; }

FOLD_TS="$(grep '^TIMESTAMP=' "$FOLD" | cut -d= -f2-)"

print "FOLD_TIMESTAMP=$FOLD_TS"

if [[ -f "$MARK" ]] && grep -qx "$FOLD_TS" "$MARK"; then
    print "ACTION=SKIP_ALREADY_PROCESSED"
    print "RESULT=PASS"
    exit 0
fi

if ! mkdir "$LOCK" 2>/dev/null; then
    print "RESULT=LOCKED"
    exit 4
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT HUP INT TERM

BEAD_LOG="$S/fold-molecule-bead.log"
ENGINE_LOG="$S/fold-molecule-engine.log"

print "ACTION=BUILD_MOLECULE"

if ! zsh "$BEAD" >"$BEAD_LOG" 2>&1; then
    tail -20 "$BEAD_LOG"
    print "RESULT=BEAD_FAIL"
    exit 5
fi

if ! zsh "$ENGINE" >"$ENGINE_LOG" 2>&1; then
    tail -20 "$ENGINE_LOG"
    print "RESULT=ENGINE_FAIL"
    exit 6
fi

tmp="${MARK}.tmp.$$"
print -r -- "$FOLD_TS" > "$tmp" || exit 7
mv -f -- "$tmp" "$MARK" || exit 7

print "ACTION=BUILD_MOLECULE"
print "GENERATION_RECORDED=$FOLD_TS"
print "RESULT=PASS"
