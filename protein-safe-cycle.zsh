#!/usr/bin/env zsh

setopt NO_NOMATCH
setopt PIPE_FAIL

R="$HOME/.config/dynu-audit/protein"
NOW="$(date +%Y%m%d-%H%M%S)"
RUN="$R/02-collector/checkpoints/safe-cycle-$NOW"
LOG="$RUN/run.log"

mkdir -p "$RUN"

exec > >(tee "$LOG") 2>&1

PASS=0
WARN=0
FAIL=0

ok() {
    echo "[PASS] $1"
    PASS=$((PASS + 1))
}

warn() {
    echo "[WARN] $1"
    WARN=$((WARN + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL=$((FAIL + 1))
}

echo '============================================================'
echo ' PROTEIN V2 — SAFE FULL CYCLE'
echo '============================================================'
echo "RUN=$NOW"
echo "ROOT=$R"
echo "CHECKPOINT=$RUN"

echo
echo '[1] ROOT'
if [[ -d "$R" ]]; then
    ok "PROTEIN_ROOT"
else
    fail "PROTEIN_ROOT_MISSING"
    exit 1
fi

echo
echo '[2] V2 EXECUTABLE'
if [[ -x "$R/protein" ]]; then
    ok "V2_EXECUTABLE"
else
    fail "V2_EXECUTABLE_MISSING"
    exit 1
fi

echo
echo '[3] ENTRYPOINT'
if [[ -x "$HOME/bin/protein" ]]; then
    TARGET="$(readlink "$HOME/bin/protein" 2>/dev/null || true)"
    if [[ "$TARGET" == "$R/protein" ]]; then
        ok "ENTRYPOINT_VALID"
    else
        fail "ENTRYPOINT_TARGET_MISMATCH"
    fi
else
    fail "USER_ENTRYPOINT_MISSING"
fi

echo
echo '[4] PATH'
case ":$PATH:" in
    *":$HOME/bin:"*)
        ok "HOME_BIN_IN_PATH"
        ;;
    *)
        fail "HOME_BIN_NOT_IN_PATH"
        ;;
esac

echo
echo '[5] DNA'
DNA_OK=1
for f in \
    "$R/00-core/dna/identity.json" \
    "$R/00-core/dna/capabilities.json" \
    "$R/00-core/dna/boundaries.json" \
    "$R/00-core/dna/dependencies.json" \
    "$R/00-core/dna/policy.json"
do
    if [[ -f "$f" ]]; then
        echo "OK $f"
    else
        echo "MISSING $f"
        DNA_OK=0
    fi
done

if (( DNA_OK )); then
    ok "DNA_COMPLETE"
else
    fail "DNA_INCOMPLETE"
    exit 1
fi

echo
echo '[6] DNA HASH'
for f in \
    "$R/00-core/dna/identity.json" \
    "$R/00-core/dna/capabilities.json" \
    "$R/00-core/dna/boundaries.json" \
    "$R/00-core/dna/dependencies.json" \
    "$R/00-core/dna/policy.json"
do
    sha256sum "$f"
done > "$RUN/dna.sha256"

cat "$RUN/dna.sha256"

echo
echo '[7] LEGACY ISOLATION'
if crontab -l 2>/dev/null | grep -q 'protein-evolution\.sh'; then
    fail "LEGACY_CRON_ACTIVE"
else
    ok "LEGACY_CRON_ISOLATED"
fi

if grep -qE 'protein-evo|protein-overview' "$HOME/.zshrc" 2>/dev/null; then
    fail "LEGACY_ZSH_ENTRYPOINT_FOUND"
else
    ok "LEGACY_ZSH_ENTRYPOINT_ISOLATED"
fi

echo
echo '[8] RESOURCE'
{
    echo "DATE=$NOW"

    awk '/MemAvailable:/ {
        printf "RAM_AVAILABLE_MB=%.0f\n",$2/1024
    }' /proc/meminfo 2>/dev/null

    df -P /data 2>/dev/null | tail -1

    echo "PROCESS_COUNT=$(ps -e 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')"
} | tee "$RUN/resource.txt"

echo
echo '[9] PROTEIN STATUS'
if "$R/protein" status > "$RUN/status.txt" 2>&1; then
    cat "$RUN/status.txt"
    ok "STATUS"
else
    cat "$RUN/status.txt"
    fail "STATUS"
fi

echo
echo '[10] OBSERVE'
if "$R/protein" observe > "$RUN/observe.txt" 2>&1; then
    cat "$RUN/observe.txt"
    ok "OBSERVE"
else
    cat "$RUN/observe.txt"
    fail "OBSERVE"
fi

echo
echo '[11] GOVERNOR'
G="$R/10-governor/background/intelligence.zsh"

if [[ -x "$G" ]]; then
    if "$G" > "$RUN/governor.txt" 2>&1; then
        cat "$RUN/governor.txt"
        ok "GOVERNOR"
    else
        cat "$RUN/governor.txt"
        warn "GOVERNOR_NONZERO"
    fi
else
    warn "GOVERNOR_SCRIPT_NOT_EXECUTABLE"
fi

echo
echo '[12] ADAPTIVE ROUTER'
AR="$R/10-governor/adaptive-route.zsh"

if [[ -x "$AR" ]]; then
    if "$AR" > "$RUN/router.txt" 2>&1; then
        cat "$RUN/router.txt"
        ok "ADAPTIVE_ROUTER"
    else
        cat "$RUN/router.txt"
        warn "ROUTER_NONZERO"
    fi
else
    warn "ADAPTIVE_ROUTER_NOT_EXECUTABLE"
fi

echo
echo '[13] MOLECULE ROUTES'
for molecule in memory storage process network; do
    echo
    echo "--- $molecule ---"
    if "$R/protein" route "$molecule" > "$RUN/route-$molecule.txt" 2>&1; then
        cat "$RUN/route-$molecule.txt"
        ok "ROUTE_$molecule"
    else
        cat "$RUN/route-$molecule.txt"
        warn "ROUTE_$molecule"
    fi
done

echo
echo '[14] EXISTING DATA — BOUNDED DISCOVERY'
echo "TERMUX_PACKAGES_EXISTS=$([[ -d "$HOME/termux-packages" ]] && echo YES || echo NO)"

if [[ -d "$HOME/termux-packages" ]]; then
    {
        echo "TOP_LEVEL_DIRS=$(find "$HOME/termux-packages" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
        echo "TOP_LEVEL_FILES=$(find "$HOME/termux-packages" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
        echo "PACKAGE_DIRS=$(find "$HOME/termux-packages/packages" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
        echo "X11_PACKAGE_DIRS=$(find "$HOME/termux-packages/x11-packages" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
        echo "DISABLED_PACKAGE_DIRS=$(find "$HOME/termux-packages/disabled-packages" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    } | tee "$RUN/termux-packages-summary.txt"
    ok "BOUNDED_PACKAGE_DISCOVERY"
else
    warn "TERMUX_PACKAGES_NOT_FOUND"
fi

echo
echo '[15] SAFETY INVARIANTS'
cat > "$RUN/safety.state" <<EOF
DNA_MUTATION=NO
DELETE=NO
MOVE=NO
QUARANTINE=NO
KILL=NO
EXTERNAL_WRITE=NO
CREDENTIAL_READ=NO
AUTO_DELETE=false
AUTO_MOVE=false
AUTO_QUARANTINE=false
AUTO_KILL=false
EOF

cat "$RUN/safety.state"

echo
echo '[16] LINEAGE'
cat > "$RUN/lineage.state" <<EOF
ROOT=DNA
PARENT=PROTEIN
GENERATION=SAFE_CYCLE
CHECKPOINT=$RUN
RIGHTS=INHERITED_ONLY
DNA_MUTATION=NO
EOF

cat "$RUN/lineage.state"

echo
echo '[17] FINAL STATUS'
"$R/protein" status | tee "$RUN/final-status.txt"

echo
echo '============================================================'
echo ' PROTEIN V2 — SAFE FULL CYCLE COMPLETE'
echo '============================================================'
echo "PASS=$PASS"
echo "WARN=$WARN"
echo "FAIL=$FAIL"
echo "CHECKPOINT=$RUN"
echo "LOG=$LOG"

if (( FAIL == 0 )); then
    echo 'RESULT=SAFE_CYCLE_PASS'
else
    echo 'RESULT=SAFE_CYCLE_REVIEW_REQUIRED'
fi

echo '============================================================'
