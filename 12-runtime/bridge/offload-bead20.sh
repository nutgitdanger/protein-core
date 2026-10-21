#!/usr/bin/env zsh
set -e

ROOT="$HOME/.config/dynu-audit"
PKG="$HOME/dynu-worker-pkg"
REMOTE="m7:~/dynu-worker"
EVIDENCE="$ROOT/protein/12-runtime/development/evidence"

mkdir -p "$EVIDENCE"

printf '%s\n' '=== OFFLOAD BEAD20 ==='

scp "$PKG/bead20-self-fold-v2-worker.py" "$PKG/bead20-relation.json" "$PKG/bead20-backbone.json" "$REMOTE/in/"

ssh m7 '
set -e
W="$HOME/dynu-worker"
cp "$W/in/bead20-self-fold-v2-worker.py" "$W/work/bead20-self-fold-v2-worker.py"
python3 -m py_compile "$W/work/bead20-self-fold-v2-worker.py"
rm -f "$W/out/bead20-self-fold-v2-result.json"
timeout 120s python3 "$W/work/bead20-self-fold-v2-worker.py" >"$W/log/bead20-self-fold-v2-offload.log" 2>&1
printf "REMOTE_RC=0\n"
tail -5 "$W/log/bead20-self-fold-v2-offload.log"
test -s "$W/out/bead20-self-fold-v2-result.json"
'

scp m7:~/dynu-worker/out/bead20-self-fold-v2-result.json "$EVIDENCE/"

python3 - "$EVIDENCE/bead20-self-fold-v2-result.json" <<'PY2'
import json
import sys

d = json.load(open(sys.argv[1]))

checks = {
    "RESULT": d.get("RESULT") == "PASS",
    "SEEDS": d.get("SEEDS") == [11,22,33,44,55,66,77,88,99,111],
    "STEPS": d.get("STEPS") == 400,
    "MAX_CONTRACTIONS": d.get("MAX_CONTRACTIONS") == 10,
    "SOURCE_RELATIONS": d.get("SOURCE_RELATIONS") == 190,
    "BACKBONE_EDGES": d.get("BACKBONE_EDGES") == 41,
    "RESULT_COUNT": len(d.get("RESULTS", [])) == 10,
}

for k, v in checks.items():
    print(f"{k}={'OK' if v else 'FAIL'}")

print("ACCEPTABLE=" + ("YES" if all(checks.values()) else "NO"))
PY2
