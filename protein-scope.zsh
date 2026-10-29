emulate -LR zsh
setopt pipefail

ROOT="${DYNU_ACTIVE_ROOT:-$HOME/.config/dynu-audit}"
RECOVERY="${DYNU_RECOVERY_ROOT:-$HOME/recovery-project-20261024-143905/repos/dynu-audit}"
OUTDIR="${XDG_CACHE_HOME:-$HOME/.cache}/dynu-audit"
mkdir -p "$OUTDIR" || exit 2
umask 077
OUT="$OUTDIR/protein-evidence-$(date -u +%Y%m%dT%H%M%SZ).tsv"

if [[ ! -d "$ROOT/protein" ]]; then
  print -u2 "STOP: Protein root missing: $ROOT/protein"
  exit 2
fi

print -r -- $'TYPE\tSTATUS\tPATH\tDETAIL' > "$OUT" || exit 3

record() {
  local detail="${4//$'\t'/ }"
  detail="${detail//$'\n'/;}"
  print -r -- "$1"$'\t'"$2"$'\t'"$3"$'\t'"$detail" >> "$OUT"
}

scan_root() {
  local base="$1" file rel target result
  if [[ ! -d "$base" || ! -r "$base" ]]; then
    record ROOT MISSING "$base" "not-readable"
    return
  fi

  record ROOT FOUND "$base" "readable"

  if git -C "$base" rev-parse --show-toplevel >/dev/null 2>&1; then
    result="$(git -C "$base" rev-parse --show-toplevel 2>/dev/null)"
    record GIT_ROOT FOUND "$base" "$result"
    result="$(git -C "$base" rev-parse --short HEAD 2>/dev/null)"
    record GIT_HEAD FOUND "$base" "$result"
    result="$(git -C "$base" status --short --branch 2>/dev/null | tr '\n' ';')"
    record GIT_STATUS FOUND "$base" "$result"
  else
    record GIT_ROOT UNKNOWN "$base" "not-a-git-root"
  fi

  while IFS= read -r -d '' file; do
    rel="${file#$base/}"
    case "$rel" in
      .git/*|*/.git/*|*/node_modules/*|*/.venv/*|*/__pycache__/*)
        continue
        ;;
    esac

    if [[ -L "$file" ]]; then
      target="$(readlink "$file" 2>/dev/null)"
      record SYMLINK FOUND "$file" "$target"
      continue
    fi

    case "$file" in
      *.zsh|*.sh|*.py|*.json|*.yaml|*.yml|*.toml|*.state|*.tsv)
        record FILE FOUND "$file" "bytes=$(wc -c < "$file" 2>/dev/null)"
        case "$file" in
          */folding.state|*/molecule.state|*/protein-relation.state)
            target="$(sha256sum "$file" 2>/dev/null)"
            record HASH VERIFIED "$file" "${target%% *}"
            ;;
        esac
        ;;
    esac
  done < <(
    find "$base" -maxdepth 7 \
      \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ \) -prune -o \
      \( -type f -o -type l \) -print0 2>/dev/null
  )
}

scan_root "$ROOT"
scan_root "$RECOVERY"

for f in \
  "$ROOT/protein/12-runtime/state/folding.state" \
  "$ROOT/protein/12-runtime/state/molecule.state" \
  "$ROOT/protein/04-relation/protein-relation.state"
do
  if [[ -f "$f" ]]; then
    state_status="$(awk -F= '$1=="STATUS"{print $2; exit}' "$f")"
    stamp="$(awk -F= '$1=="TIMESTAMP"{print $2; exit}' "$f")"
    record STATE FOUND "$f" "STATUS=${state_status:-UNKNOWN};TIMESTAMP=${stamp:-UNKNOWN}"
  else
    record STATE MISSING "$f" "not-found"
  fi
done

for f in \
  "$ROOT/protein/05-validator/validator.zsh" \
  "$ROOT/protein/12-runtime/conveyor/units/daemon.zsh" \
  "$ROOT/protein/12-runtime/conveyor/units/master-daemon.zsh" \
  "$ROOT/protein/12-runtime/conveyor/units/supervisor.zsh"
do
  if [[ -f "$f" ]]; then
    record COMPONENT FOUND "$f" "not-executed"
  else
    record COMPONENT MISSING "$f" "not-found-at-expected-path"
  fi
done

print "REPORT=$OUT"
print "MODE=READ_ONLY"
print "EXECUTED_PROJECT_FILES=0"
print "NOTE=FOUND means present, not validated or running."
awk -F '\t' 'NR>1 {n[$1 FS $2]++} END {for (k in n) print k, n[k]}' "$OUT" | sort
