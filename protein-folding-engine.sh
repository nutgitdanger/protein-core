#!/usr/bin/env zsh
set -u

ROOT="$HOME/.config/dynu-audit"
P="$ROOT/protein"
STATE="$P/12-runtime/state/folding.state"
OUT="$P/12-runtime/state/folding.result"

print ">>> FOLDING"
print "ROOT=$ROOT"
print "PROTEIN=$P"

if [[ ! -d "$ROOT" || ! -d "$P" ]]; then
    print "[FAIL] invalid repository root: $ROOT"
    exit 2
fi

fibers=0
molecules=0
states=0

if [[ -d "$P/00-core/map/fibers" ]]; then
    fibers=$(find "$P/00-core/map/fibers" -type f 2>/dev/null | wc -l)
fi

if [[ -d "$P/11-molecules" ]]; then
    molecules=0
for bead in "$P/11-molecules/beads"/bead-*.state; do
    [[ -f "$bead" ]] || continue
    grep -q "^TYPE=MOLECULE_BEAD$" "$bead" || continue
    grep -q "^STATUS=BUILT$" "$bead" || continue
    (( molecules++ ))
done
fi

states=$(find "$P/12-runtime/state" -type f 2>/dev/null | wc -l)

stamp=$(date +%Y%m%d_%H%M%S)

tmpdir="$P/12-runtime/state/.folding-tmp-$$"
mkdir -p "$tmpdir" || exit 3
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

{
    print "ENGINE=folding"
    print "STATUS=FOLDED"
    print "TIMESTAMP=$stamp"
    print "ROOT=$ROOT"
    print "FIBERS=$fibers"
    print "MOLECULES=$molecules"
    print "STATES=$states"
} > "$tmpdir/folding.state"

{
    print "FOLDING_RESULT=OK"
    print "TIMESTAMP=$stamp"
    print "FIBERS=$fibers"
    print "MOLECULES=$molecules"
    print "STATES=$states"
} > "$tmpdir/folding.result"

[[ -s "$tmpdir/folding.state" && -s "$tmpdir/folding.result" ]] || exit 4
grep -q "^STATUS=FOLDED$" "$tmpdir/folding.state" || exit 5
grep -q "^FOLDING_RESULT=OK$" "$tmpdir/folding.result" || exit 6
grep -q "^TIMESTAMP=$stamp$" "$tmpdir/folding.state" || exit 7
grep -q "^TIMESTAMP=$stamp$" "$tmpdir/folding.result" || exit 8

mv "$tmpdir/folding.state" "$STATE" || exit 9
mv "$tmpdir/folding.result" "$OUT" || exit 10

print "[OK] folding state written"
cat "$STATE"
