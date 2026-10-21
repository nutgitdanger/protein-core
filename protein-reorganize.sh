#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/.config/dynu-audit"
cd "$ROOT"

TS="$(date +%Y%m%d-%H%M%S)"
RUN="$ROOT/protein/12-runtime/bridge/reorganize-$TS"
mkdir -p "$RUN"

exec > >(tee "$RUN/run.log") 2>&1

echo "=== PROTEIN REORGANIZATION ==="
echo "TIME=$TS"
echo "ROOT=$ROOT"
echo

echo "=== PRECHECK ==="
test -x "$ROOT/protein/protein"
test -d "$ROOT/protein/00-core"
test -d "$ROOT/protein/11-molecules"
test -d "$ROOT/protein/12-runtime"

echo "PRECHECK=PASS"
echo

echo "=== GIT BEFORE ==="
git status --short
echo

echo "=== CURRENT STRUCTURE ==="
find . -maxdepth 3 -print | sort > "$RUN/tree.before"
wc -l "$RUN/tree.before"
echo

echo "=== REQUIRED GROUPS ==="

mkdir -p \
  raw \
  evidence \
  runs \
  reports \
  state \
  legacy \
  protein/00-core/map \
  protein/04-relation \
  protein/10-governor \
  protein/12-runtime/bridge \
  protein/12-runtime/state

echo "SOURCE=preserve"
echo "RAW=raw"
echo "RESOURCE=protein/11-molecules"
echo "EVIDENCE=evidence"
echo "RUN=protein/12-runtime/bridge"
echo "STATE=state + protein/12-runtime/state"
echo "REPORT=reports"
echo "LEGACY=legacy"
echo "MAP=protein/00-core/map"
echo "RELATION=protein/04-relation"
echo "DECISION=protein/10-governor"
echo

echo "=== EXISTING DATA PRESERVED ==="
for d in raw evidence runs reports state legacy \
         protein/11-molecules \
         protein/12-runtime/bridge \
         protein/12-runtime/state \
         protein/00-core/map \
         protein/04-relation \
         protein/10-governor
do
    if [ -d "$d" ]; then
        echo "FOUND $d"
    fi
done
echo

echo "=== RUN CAPSULES ==="
find protein/12-runtime/bridge \
  -maxdepth 1 -type d -name 'protein-full-*' -print 2>/dev/null | sort || true
echo

echo "=== MAP ==="
if [ -f protein/00-core/map/provenance.tsv ]; then
    cat protein/00-core/map/provenance.tsv
else
    echo "MAP_PROVENANCE=NOT_FOUND"
fi
echo

echo "=== AWS STATUS ==="
./protein/protein route aws > "$RUN/aws.route" 2>&1 || true
cat "$RUN/aws.route"
echo

echo "=== CORE ROUTES ==="
PASS=0
FAIL=0

for m in system memory storage process network dns git projects; do
    if ./protein/protein route "$m" > "$RUN/$m.route" 2>&1; then
        echo "PASS $m"
        PASS=$((PASS+1))
    else
        echo "FAIL $m"
        FAIL=$((FAIL+1))
    fi
done

echo "ROUTES_EXPECTED=8"
echo "ROUTES_PASSED=$PASS"
echo "ROUTES_FAILED=$FAIL"

echo
echo "=== REORGANIZATION POLICY ==="
echo "SOURCE: immutable"
echo "RAW: immutable"
echo "SUCCESS BASELINES: immutable"
echo "RUN CAPSULES: immutable"
echo "LEGACY: reference-only"
echo "UNKNOWN: not moved automatically"
echo "EXECUTABLES: not moved automatically"
echo "ACTIVE PROJECT FILES: not moved automatically"
echo

echo "=== HASH OF PRE-STATE ==="
sha256sum "$RUN/tree.before" > "$RUN/tree.before.sha256"

echo "=== RESULT ==="
if [ "$FAIL" -eq 0 ]; then
    echo "CORE_ROUTES=PASS"
else
    echo "CORE_ROUTES=FAIL"
fi

echo "REORGANIZATION=STRUCTURE_PREPARED"
echo "NO_EXISTING_DATA_MOVED=YES"
echo "NO_EXISTING_DATA_DELETED=YES"

echo
echo "=== GIT AFTER ==="
git status --short

echo
echo "RUN_CAPSULE=$RUN"
