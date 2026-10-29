#!/data/data/com.termux/files/usr/bin/zsh

setopt NO_NOMATCH

CORE="$HOME/protein"
AUDIT="$HOME/.config/dynu-audit/protein"
STATE="$CORE/state"

echo "============================================================"
echo " PROTEIN BOOTSTRAP — SAFE EXECUTION"
echo "============================================================"

# ------------------------------------------------------------
# 1. Identity
# ------------------------------------------------------------
echo
echo "[1] IDENTITY"

[[ -d "$CORE" ]] || { echo "CORE=FAIL"; exit 1; }
[[ -d "$AUDIT" ]] || { echo "AUDIT=FAIL"; exit 1; }

echo "CORE=$CORE"
echo "AUDIT=$AUDIT"
echo "CORE_STATUS=OK"
echo "AUDIT_STATUS=OK"

# ------------------------------------------------------------
# 2. Required core
# ------------------------------------------------------------
echo
echo "[2] CORE COMPONENTS"

for d in \
    00-core \
    01-observer \
    02-correlator \
    03-decision \
    04-response \
    05-memory \
    06-interface \
    07-safety \
    08-tests \
    09-log
do
    if [[ -d "$CORE/$d" ]]; then
        echo "PASS $d"
    else
        echo "FAIL $d"
    fi
done

# ------------------------------------------------------------
# 3. Canonical schema
# ------------------------------------------------------------
echo
echo "[3] SCHEMA"

SCHEMA="$CORE/00-core/schema/state/model.txt"

if [[ -f "$SCHEMA" ]]; then
    echo "SCHEMA=PASS"
    echo "SCHEMA_SHA256=$(sha256sum "$SCHEMA" | awk '{print $1}')"
else
    echo "SCHEMA=FAIL"
    exit 1
fi

# ------------------------------------------------------------
# 4. Observer execution
# ------------------------------------------------------------
echo
echo "[4] OBSERVER TEST"

OBS="$CORE/01-observer"

for f in cpu memory process; do
    FILE="$OBS/$f.zsh"

    if [[ ! -f "$FILE" ]]; then
        echo "$f=NOT_FOUND"
        continue
    fi

    if zsh -n "$FILE" >/dev/null 2>&1; then
        echo "$f=SYNTAX_OK"
    else
        echo "$f=SYNTAX_FAIL"
        continue
    fi

    OUT="$(zsh "$FILE" 2>&1)"

    if [[ $? -eq 0 ]]; then
        echo "$f=EXECUTION_OK"
    else
        echo "$f=EXECUTION_FAIL"
    fi

    printf '%s\n' "$OUT" |
        grep -E '^(CORES|LOAD_|MEMORY_|SWAP_|PROCESS_COUNT|RUNNING|SLEEPING|STATUS=)' |
        head -30
done

# ------------------------------------------------------------
# 5. State record
# ------------------------------------------------------------
echo
echo "[5] CURRENT STATE"

mkdir -p "$STATE"

NOW="$(date '+%Y-%m-%dT%H:%M:%S%z')"
HOST="$(hostname 2>/dev/null || echo UNKNOWN)"

{
    echo "STATE=ACTIVE"
    echo "SOURCE=protein-bootstrap"
    echo "VALUE=CORE_OPERATIONAL"
    echo "BASELINE=INITIAL"
    echo "DELTA=NONE"
    echo "SIGNAL=INFO"
    echo "CONFIDENCE=HIGH"
    echo "TIMESTAMP=$NOW"
    echo "HOST=$HOST"
    echo "CORE=$CORE"
    echo "AUDIT=$AUDIT"
} > "$STATE/current.state"

# ------------------------------------------------------------
# 6. Bridge contract
# ------------------------------------------------------------
echo
echo "[6] BRIDGE"

mkdir -p "$CORE/00-core/identity"

cat > "$CORE/00-core/identity/roots.conf" <<BRIDGE
CORE_ROOT=$CORE
AUDIT_ROOT=$AUDIT
CORE_ROLE=LOGIC
AUDIT_ROLE=EVIDENCE
DATA_FLOW=CORE_TO_AUDIT
WRITE_POLICY=NO_OVERWRITE
BRIDGE_STATUS=ACTIVE
BRIDGE

echo "BRIDGE=ACTIVE"

# ------------------------------------------------------------
# 7. Health result
# ------------------------------------------------------------
echo
echo "[7] HEALTH"

FAIL=0

for d in \
    00-core \
    01-observer \
    02-correlator \
    03-decision \
    04-response \
    05-memory \
    06-interface \
    07-safety \
    08-tests \
    09-log
do
    [[ -d "$CORE/$d" ]] || FAIL=1
done

[[ -f "$SCHEMA" ]] || FAIL=1
[[ -f "$STATE/current.state" ]] || FAIL=1
[[ -f "$CORE/00-core/identity/roots.conf" ]] || FAIL=1

if (( FAIL == 0 )); then
    echo "PROTEIN_STATUS=OPERATIONAL"
    echo "RESULT=SUCCESS"
else
    echo "PROTEIN_STATUS=DEGRADED"
    echo "RESULT=FAIL"
fi

echo
echo "============================================================"
echo " BOOTSTRAP COMPLETE"
echo " NO FILES MOVED"
echo " NO FILES DELETED"
echo " NO EXISTING FILE OVERWRITTEN EXCEPT NEW STATE/BRIDGE FILES"
echo "============================================================"
