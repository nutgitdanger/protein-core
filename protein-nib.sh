#!/usr/bin/env zsh
set -u

ROOT="$HOME/.config/dynu-audit"
P="$ROOT/protein"
STATE="$P/12-runtime/state"
EVIDENCE="$STATE/nib-evidence"
LOCK="$STATE/.nib.lock"
FOLD="$ROOT/protein-folding-engine.sh"
STATUS="$ROOT/protein-master-status.sh"
STAMP="$(date +%Y%m%d_%H%M%S)"
RUN="$EVIDENCE/run-$STAMP"
LOG="$RUN.log"

mkdir -p "$EVIDENCE" || exit 10

if [[ ! -d "$ROOT" || ! -d "$P" ]]; then
    print "[FAIL] ROOT_INVALID"
    exit 11
fi

if [[ -e "$LOCK" ]]; then
    print "[FAIL] NIB_ALREADY_RUNNING"
    print "LOCK=$LOCK"
    exit 12
fi

mkdir "$LOCK" || exit 12
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT HUP INT TERM

{
    print "NIB=pen-nib"
    print "TIMESTAMP=$STAMP"
    print "ROOT=$ROOT"
    print "PROTEIN=$P"
    print "POLICY=CHECK_OBSERVE_POLICY_DISCOVER_MEASURE_EVIDENCE_VERIFY_PROMOTE_OR_FOLDBACK"
    print "ROOT_MUTATION=NO"
    print "AWS_MUTATION=NO"
    print "BACKGROUND=NO"
    print "DELETE=NO"
    print "MOVE=NO"
    print "RESOURCE_LIMIT=30s"
    print "FOLDING_ENGINE=$FOLD"
    print "FOLDING_SHA256=$(sha256sum "$FOLD" 2>/dev/null | awk '{print $1}')"
    print "STATUS_ENGINE=$STATUS"
    print
} > "$LOG" || exit 13

if [[ ! -f "$FOLD" ]]; then
    print "RESULT=FOLDING_ENGINE_MISSING" >> "$LOG"
    exit 20
fi

if [[ ! -f "$STATUS" ]]; then
    print "RESULT=STATUS_ENGINE_MISSING" >> "$LOG"
    exit 21
fi

print "=== FOLDING ===" >> "$LOG"
if timeout 30s zsh "$FOLD" >> "$LOG" 2>&1; then
    print "FOLDING=PASS" >> "$LOG"
else
    rc=$?
    print "FOLDING=FAIL"
    print "FOLDING_RC=$rc" >> "$LOG"
    print "RESULT=FOLDBACK_REQUIRED" >> "$LOG"
    exit 30
fi

print "=== STATUS ===" >> "$LOG"
if zsh "$STATUS" >> "$LOG" 2>&1; then
    print "STATUS=PASS" >> "$LOG"
else
    rc=$?
    print "STATUS=FAIL" >> "$LOG"
    print "STATUS_RC=$rc" >> "$LOG"
    print "RESULT=VERIFY_FAILED" >> "$LOG"
    exit 31
fi

print "RESULT=VERIFIED" >> "$LOG"
print "EVIDENCE=$LOG"

exit 0
