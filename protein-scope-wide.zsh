emulate -LR zsh
setopt pipefail
umask 077

ACTIVE="${DYNU_ACTIVE_ROOT:-$HOME/.config/dynu-audit}"
RECOVERY="${DYNU_RECOVERY_ROOT:-$HOME/recovery-project-20261024-143905/repos/dynu-audit}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dynu-audit"
mkdir -p "$CACHE" || exit 2

OUT="$CACHE/protein-wide-$(date -u +%Y%m%dT%H%M%SZ).tsv"
ROOTLIST="$CACHE/protein-roots-$$.txt"
trap 'rm -f "$ROOTLIST"' EXIT
: > "$ROOTLIST"

add_root() {
  local p="$1"
  [[ -d "$p" ]] || return
  p="${p:A}"
  grep -Fqx -- "$p" "$ROOTLIST" 2>/dev/null || print -r -- "$p" >> "$ROOTLIST"
}

add_root "$ACTIVE"
add_root "$RECOVERY"
add_root "$HOME/protein-core"
add_root "$HOME/projects"
add_root "$HOME/repos"
add_root "$HOME/workspaces"

while IFS= read -r -d '' gitdir; do
  add_root "${gitdir:h}"
done < <(
  find "$HOME" -maxdepth 4 \
    \( -name .cache -o -name node_modules -o -name .venv -o -name _archive -o -name 'Downloads' \) -prune -o \
    -type d -name .git -print0 2>/dev/null
)

print -r -- $'TYPE\tSTATUS\tROOT\tPATH\tDETAIL' > "$OUT" || exit 3

record() {
  local detail="${5//$'\t'/ }"
  detail="${detail//$'\n'/;}"
  print -r -- "$1"$'\t'"$2"$'\t'"$3"$'\t'"$4"$'\t'"$detail" >> "$OUT"
}

while IFS= read -r base; do
  [[ -d "$base" ]] || continue
  record ROOT FOUND "$base" "$base" "readable"

  if git -C "$base" rev-parse --show-toplevel >/dev/null 2>&1; then
    record GIT FOUND "$base" "$base" "$(git -C "$base" rev-parse --short HEAD 2>/dev/null)"
    record GIT_STATUS FOUND "$base" "$base" "$(git -C "$base" status --short --branch 2>/dev/null | tr '\n' ';')"
  fi

  while IFS= read -r -d '' file; do
    if [[ -L "$file" ]]; then
      target="$(readlink "$file" 2>/dev/null)"
      resolved="${file:A}"
      if [[ "$resolved" == "$base"/* ]]; then
        record SYMLINK IN_SCOPE "$base" "$file" "$target"
      else
        record SYMLINK OUT_OF_SCOPE "$base" "$file" "$target"
      fi
      continue
    fi

    [[ -f "$file" ]] || continue
    case "$file" in
      *.zsh|*.sh|*.py|*.json|*.yaml|*.yml|*.toml|*.state|*.tsv|*.md)
        bytes="$(wc -c < "$file" 2>/dev/null)"
        record FILE FOUND "$base" "$file" "bytes=$bytes"
        ;;
    esac
  done < <(
    find "$base" -maxdepth 7 \
      \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ -o -name .cache -o -name _archive \) -prune -o \
      \( -type f -o -type l \) -print0 2>/dev/null
  )
done < "$ROOTLIST"

for f in \
  "$ACTIVE/protein/12-runtime/state/folding.state" \
  "$ACTIVE/protein/12-runtime/state/molecule.state" \
  "$ACTIVE/protein/04-relation/protein-relation.state"
do
  if [[ -f "$f" ]]; then
    digest="$(sha256sum "$f" 2>/dev/null)"
    stamp="$(awk -F= '$1=="TIMESTAMP"{print $2; exit}' "$f")"
    state_status="$(awk -F= '$1=="STATUS"{print $2; exit}' "$f")"
    record STATE FOUND "$ACTIVE" "$f" "STATUS=${state_status:-UNKNOWN};TIMESTAMP=${stamp:-UNKNOWN};SHA256=${digest%% *}"
  else
    record STATE MISSING "$ACTIVE" "$f" "not-found"
  fi
done

print "REPORT=$OUT"
print "MODE=READ_ONLY"
print "PROJECT_FILES_EXECUTED=0"
print "ROOTS=$(grep -c . "$ROOTLIST")"
print "NOTE=Discovery does not grant execution permission."
awk -F '\t' 'NR>1 {n[$1 FS $2]++} END {for (k in n) print k, n[k]}' "$OUT" | sort
