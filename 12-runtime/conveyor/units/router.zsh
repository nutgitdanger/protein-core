#!/data/data/com.termux/files/usr/bin/zsh

setopt NO_BANG_HIST

ROOT="$HOME/.config/dynu-audit"
C="$ROOT/protein/12-runtime/conveyor"

input="${1:-}"

if [[ -z "$input" || ! -f "$input" ]]; then
  printf 'ROUTE=REJECT\nREASON=INPUT_MISSING\n'
  exit 1
fi

sha="$(sha256sum "$input" | awk '{print $1}')"
size="$(stat -c %s "$input" 2>/dev/null || printf '0')"

if (( size == 0 )); then
  printf 'ROUTE=REJECT\nREASON=INPUT_EMPTY\n'
  exit 1
fi

printf 'ROUTE=EC2\n'
printf 'INPUT=%s\n' "$input"
printf 'INPUT_SHA256=%s\n' "$sha"
printf 'SIZE=%s\n' "$size"
printf 'COMPUTE=EC2\n'
printf 'VALIDATION=REQUIRED\n'
