setopt NO_BANG_HIST
set -u

P="$HOME/.config/dynu-audit/protein"
RUN="${1:?missing run directory}"
SANDBOX="$RUN/sandbox"
COPY="$SANDBOX/.config/dynu-audit/protein"
BEADS="$COPY/11-molecules/beads"
CORE="$P/12-runtime/state"

print -r -- "RUN=$RUN"
print -r -- "MODE=ISOLATED_LAYER_TEST"
print -r -- "LIVE_STATE_WRITE=NO"
print -r -- "LIVE_WORKER=NOT_STARTED"

fail() {
  print -r -- "RESULT=BLOCKED"
  print -r -- "REASON=$1"
  exit 1
}

[[ -d "$P" ]] || fail "PROTEIN_ROOT_MISSING"
[[ -f "$CORE/folding.state" ]] || fail "FOLDING_STATE_MISSING"
[[ -f "$P/11-molecules/beads/capture-symlink-axis.sh" ]] || fail "CAPTURE_SCRIPT_MISSING"
[[ -f "$P/11-molecules/beads/extend-bead-from-symlink-axis.sh" ]] || fail "EXTEND_SCRIPT_MISSING"

{
  print -r -- "ROOT=$P"
  print -r -- "FOLDING_SHA256=$(sha256sum "$CORE/folding.state" | awk '{print $1}')"
  if [[ -f "$CORE/molecule.state" ]]; then
    print -r -- "MOLECULE_SHA256=$(sha256sum "$CORE/molecule.state" | awk '{print $1}')"
  else
    print -r -- "MOLECULE_STATE=ABSENT"
  fi
  if [[ -f "$P/11-molecules/live.molecule" ]]; then
    print -r -- "LIVE_MOLECULE_SHA256=$(sha256sum "$P/11-molecules/live.molecule" | awk '{print $1}')"
  fi
  if [[ -f "$P/04-relation/protein-relation.state" ]]; then
    print -r -- "RELATION_SHA256=$(sha256sum "$P/04-relation/protein-relation.state" | awk '{print $1}')"
  fi
} > "$RUN/root-evidence.state"

mkdir -p "$SANDBOX/.config/dynu-audit"
cp -a "$P" "$COPY" || fail "SANDBOX_COPY_FAILED"

print -r -- "LAYER_0=PASS_ROOT_AND_SOURCE_PRESENT"

HOME="$SANDBOX" zsh "$COPY/11-molecules/beads/capture-symlink-axis.sh" > "$RUN/capture.log" 2>&1 || {
  cat "$RUN/capture.log"
  fail "CAPTURE_LAYER_FAILED"
}

AXIS="$BEADS/symlink-axis.latest"
[[ -f "$AXIS" ]] || fail "AXIS_OUTPUT_MISSING"
RAW="$(sed -n 's/^SOURCE=//p' "$AXIS" | head -n 1)"
[[ -n "$RAW" && -f "$RAW" ]] || fail "RAW_EVIDENCE_MISSING"

print -r -- "LAYER_1=PASS_CAPTURE"
cat "$RUN/capture.log"

HOME="$SANDBOX" zsh "$COPY/11-molecules/beads/extend-bead-from-symlink-axis.sh" > "$RUN/extend.log" 2>&1 || {
  cat "$RUN/extend.log"
  fail "BEAD_EXTENSION_FAILED"
}

BEAD_AXIS="$BEADS/bead-axis.latest"
[[ -f "$BEAD_AXIS" ]] || fail "BEAD_AXIS_OUTPUT_MISSING"

print -r -- "LAYER_2=PASS_BEAD_AXIS_GENERATED"
cat "$RUN/extend.log"

if grep -q '^AXIS_BEAD=axis\.' "$BEAD_AXIS"; then
  print -r -- "CHECK=FAIL_REPORTS_COUNTED_AS_BEADS"
  print -r -- "DETAIL=Existing bead-axis reports appear to be included as bead units"
else
  print -r -- "CHECK=NO_REPORT_AS_BEAD_EVIDENCE"
fi

ACCEPT="$COPY/00-core/map/governor/evolution_acceptance.py"
if [[ -f "$ACCEPT" ]]; then
  print -r -- "LAYER_3=ACCEPTANCE_SOURCE_PRESENT_NOT_EXECUTED"
  print -r -- "REASON=Interface_not_yet_verified"
else
  print -r -- "LAYER_3=BLOCKED_ACCEPTANCE_SOURCE_MISSING"
fi

print -r -- "LAYER_4=NOT_RUN"
print -r -- "REASON=No_verified_acceptance_to_state_update_connector"
print -r -- "LIVE_STATE_WRITE=NO"
print -r -- "LIVE_QUEUE_SUBMITTED=NO"
print -r -- "SUPERVISOR_RESTARTED=NO"
print -r -- "EVIDENCE_DIR=$RUN"
print -r -- "RESULT=FIRST_LAYERS_COMPLETED"
