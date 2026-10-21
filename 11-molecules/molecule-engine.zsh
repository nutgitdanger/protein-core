#!/usr/bin/env zsh
set -u

ROOT="$HOME/.config/dynu-audit"
P="$ROOT/protein"
FOLD="$P/12-runtime/state/folding.state"
STATE="$P/12-runtime/state/molecule-engine.state"
OUT="$P/11-molecules/molecule-engine.molecule"

print ">>> MOLECULES"
print "ROOT=$ROOT"

if [[ ! -f "$FOLD" ]]; then
    print "[WAIT] folding.state ยังไม่มี"
    exit 2
fi

typeset -i fibers=0
typeset -i molecules=0
typeset -i states=0

fibers=$(find "$P/00-core/map/fibers" -type f 2>/dev/null | wc -l)
molecules=0
for bead in "$P/11-molecules/beads"/bead-*.state; do
    [[ -f "$bead" ]] || continue
    grep -q "^TYPE=MOLECULE_BEAD$" "$bead" || continue
    grep -q "^STATUS=BUILT$" "$bead" || continue
    (( molecules++ ))
done
states=$(find "$P/12-runtime/state" -type f 2>/dev/null | wc -l)

stamp=$(date +%Y%m%d_%H%M%S)

write_atomic() {
    local target="$1"
    local tmp

    tmp=$(mktemp "${target}.tmp.XXXXXX") || return 1

    if ! cat > "$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    if ! mv -f -- "$tmp" "$target"; then
        rm -f "$tmp"
        return 1
    fi
}

write_atomic "$OUT" <<EOF
TYPE=MOLECULE
STATUS=ACTIVE
TIMESTAMP=$stamp
FIBERS=$fibers
MOLECULES=$molecules
STATES=$states
SOURCE=$FOLD
EOF

write_atomic "$STATE" <<EOF
ENGINE=molecules
STATUS=ACTIVE
TIMESTAMP=$stamp
FIBERS=$fibers
MOLECULES=$molecules
STATES=$states
OUTPUT=$OUT
EOF

print
print "=== LIVE MOLECULE ==="
cat "$OUT"

print
print "=== MOLECULE STATE ==="
cat "$STATE"
