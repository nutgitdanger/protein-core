#!/usr/bin/env zsh
set -e

MAX_GENERATIONS=5
MAX_RUNTIME=60
MAX_CANDIDATES=5
MAX_NEW_FILES=5
MAX_OUTPUT_BYTES=$((5 * 1024 * 1024))
WORKER_TIMEOUT=20

ROOT="$HOME/.config/dynu-audit"
PKG="$HOME/dynu-worker-pkg"
DEV="$ROOT/protein/12-runtime/development"
RUN="$DEV/evolution"

WORKER="$PKG/bead20-self-fold-v2-worker.py"
RELATION="$PKG/bead20-relation.json"
BACKBONE="$PKG/bead20-backbone.json"

START=$(date +%s)
RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$RUN/$RUN_ID"

mkdir -p "$OUT"

count_files() {
  find "$OUT" -type f 2>/dev/null | wc -l
}

count_bytes() {
  du -sb "$OUT" 2>/dev/null | awk '{print $1}'
}

stop_check() {
  local now elapsed files bytes

  now=$(date +%s)
  elapsed=$((now - START))
  files=$(count_files)
  bytes=$(count_bytes)

  if (( elapsed >= MAX_RUNTIME )); then
    print "STOP=MAX_RUNTIME"
    return 1
  fi

  if (( files >= MAX_NEW_FILES )); then
    print "STOP=MAX_NEW_FILES"
    return 1
  fi

  if (( bytes >= MAX_OUTPUT_BYTES )); then
    print "STOP=MAX_OUTPUT"
    return 1
  fi

  return 0
}

validate_result() {
  local result="$1"

  python3 - "$result" <<'PY'
import json
import sys

try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print("VALIDATION=FAIL")
    raise SystemExit(1)

checks = {
    "RESULT": d.get("RESULT") == "PASS",
    "SEEDS": d.get("SEEDS") == [11,22,33,44,55,66,77,88,99,111],
    "STEPS": d.get("STEPS") == 400,
    "MAX_CONTRACTIONS": d.get("MAX_CONTRACTIONS") == 10,
    "SOURCE_RELATIONS": d.get("SOURCE_RELATIONS") == 190,
    "BACKBONE_EDGES": d.get("BACKBONE_EDGES") == 41,
    "RESULT_COUNT": len(d.get("RESULTS", [])) == 10,
}

print("VALIDATION=" + ("PASS" if all(checks.values()) else "FAIL"))

raise SystemExit(0 if all(checks.values()) else 1)
PY
}

score_result() {
  python3 - "$1" <<'PY'
import json
import sys

d = json.load(open(sys.argv[1]))
runs = d.get("RESULTS", [])

values = [
    float(x["IMPROVEMENT_PERCENT"])
    for x in runs
    if isinstance(x.get("IMPROVEMENT_PERCENT"), (int, float))
]

if not values:
    print("0")
else:
    print(f"{sum(values) / len(values):.6f}")
PY
}

write_generation() {
  local generation="$1"
  local candidate="$2"
  local result="$3"
  local validation="$4"
  local score="$5"
  local file="$OUT/generation-$generation.json"

  python3 - "$file" "$RUN_ID" "$generation" "$candidate" "$validation" "$score" "$result" <<'PY'
import json
import sys
import hashlib

out, run_id, generation, candidate, validation, score, result = sys.argv[1:]

data = open(result, "rb").read()
sha = hashlib.sha256(data).hexdigest()

d = {
    "run_id": run_id,
    "generation": int(generation),
    "candidate": int(candidate),
    "worker_result_sha256": sha,
    "validation": validation,
    "score": float(score),
    "accepted": validation == "PASS",
    "status": "ACCEPTED" if validation == "PASS" else "REJECTED",
}

with open(out, "w") as f:
    json.dump(d, f, separators=(",", ":"))
    f.write("\n")
PY
}

print "STATUS=START"
print "RUN_ID=$RUN_ID"
print "DESTINATION=$OUT"
print "MAX_GENERATIONS=$MAX_GENERATIONS"
print "MAX_RUNTIME=$MAX_RUNTIME"
print "MAX_CANDIDATES=$MAX_CANDIDATES"
print "MAX_NEW_FILES=$MAX_NEW_FILES"
print "MAX_OUTPUT_BYTES=$MAX_OUTPUT_BYTES"
print "CANONICAL_WRITE=NO"

if [[ ! -s "$WORKER" || ! -s "$RELATION" || ! -s "$BACKBONE" ]]; then
  print "STATUS=ABORTED"
  print "REASON=WORKER_INPUT_MISSING"
  exit 1
fi

generation=0
candidate=0

while (( generation < MAX_GENERATIONS )); do
  stop_check || break

  generation=$((generation + 1))
  candidate=$generation

  if (( candidate > MAX_CANDIDATES )); then
    print "STOP=MAX_CANDIDATES"
    break
  fi

  TMP=$(mktemp -d "$HOME/.cache/protein-evolution.XXXXXX")
  RESULT="$TMP/result.json"

  cleanup() {
    rm -rf "$TMP"
  }

  trap cleanup EXIT INT TERM

  (
    cd "$TMP"
    cp "$WORKER" worker.py
    cp "$RELATION" bead20-relation.json
    cp "$BACKBONE" bead20-backbone.json
    rm -f "$RESULT"
    timeout "${WORKER_TIMEOUT}s" python3 worker.py > worker.log 2>&1
  ) || true

  if [[ -s "$RESULT" ]]; then
    if validate_result "$RESULT"; then
      VALIDATION=PASS
      SCORE=$(score_result "$RESULT")
      ACCEPTED=YES
    else
      VALIDATION=FAIL
      SCORE=0
      ACCEPTED=NO
    fi

    write_generation "$generation" "$candidate" "$RESULT" "$VALIDATION" "$SCORE"

    print "GENERATION=$generation CANDIDATE=$candidate VALIDATION=$VALIDATION ACCEPTED=$ACCEPTED SCORE=$SCORE"
  else
    write_generation "$generation" "$candidate" /dev/null FAIL 0
    print "GENERATION=$generation CANDIDATE=$candidate VALIDATION=FAIL RESULT=MISSING"
  fi

  cleanup
  trap - EXIT INT TERM

  stop_check || break
done

print "STATUS=STOPPED"
print "RUN_ID=$RUN_ID"
print "GENERATIONS=$generation"
print "FILES=$(count_files)"
print "BYTES=$(count_bytes)"
print "DESTINATION=$OUT"
print "CANONICAL_WRITE=NO"
