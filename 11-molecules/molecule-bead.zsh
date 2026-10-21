#!/usr/bin/env zsh
set -u

ROOT="$HOME/.config/dynu-audit"
P="$ROOT/protein"
M="$P/11-molecules"
S="$P/12-runtime/state"
F="$P/00-core/map/fibers"

FOLD="$S/folding.state"
MOLECULE="$S/molecule.state"
BEAD="$M/beads"
LIVE="$M/live.molecule"

print ">>> MOLECULE BEAD BUILDER"
print "ROOT=$ROOT"

if [[ ! -f "$FOLD" ]]; then
    print "[WAIT] folding.state ยังไม่มี"
    exit 2
fi

typeset -i bead_count=0
typeset -i next_id=1

if [[ -f "$MOLECULE" ]]; then
    old=$(grep '^BEADS=' "$MOLECULE" 2>/dev/null | cut -d= -f2)
    [[ "$old" == <-> ]] && bead_count=$old
fi

next_id=$((bead_count + 1))

STAMP=$(date +%Y%m%d_%H%M%S)
BEAD_FILE="$BEAD/bead-${next_id}.state"

if [[ -e "$BEAD_FILE" ]]; then
    print "[STOP] bead already exists: $BEAD_FILE"
    print "[STOP] canonical BEADS=$bead_count; refusing overwrite"
    exit 3
fi

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

write_atomic "$BEAD_FILE" <<EOF
TYPE=MOLECULE_BEAD
ID=$next_id
STATUS=BUILT
TIMESTAMP=$STAMP
SOURCE=folding.state
ROOT=$ROOT
EOF

bead_count=$next_id

write_atomic "$MOLECULE" <<EOF
ENGINE=molecules
STATUS=ACTIVE
BEADS=$bead_count
LAST_BEAD=$next_id
TIMESTAMP=$STAMP
SOURCE=$FOLD
NEXT=$BEAD_FILE
EOF

write_atomic "$LIVE" <<EOF
TYPE=MOLECULE_CHAIN
STATUS=ACTIVE
BEADS=$bead_count
LAST_BEAD=$next_id
TIMESTAMP=$STAMP
SOURCE=$MOLECULE
EOF

print "[BEAD] $next_id"
print "[OK] molecule chain extended"

print
print "=== MOLECULE STATE ==="
cat "$MOLECULE"

print
print "=== LIVE MOLECULE ==="
cat "$LIVE"

print
print "=== BEAD CHAIN ==="
ls -1 "$BEAD"/bead-*.state 2>/dev/null
