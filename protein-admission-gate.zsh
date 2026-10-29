#!/usr/bin/env zsh

set -u

ROOT="${PROTEIN_ROOT:-${HOME}/.config/dynu-audit}"
POLICY="$ROOT/protein/00-core/policy/protection.policy"

die() {
    print -u2 -- "ADMISSION BLOCKED: $1"
    exit 42
}

[[ -f "$POLICY" ]] || die "policy missing"

SOURCE="${1:-}"
[[ -n "$SOURCE" ]] || die "source required"
[[ -e "$SOURCE" ]] || die "source does not exist"

SOURCE="$(realpath "$SOURCE" 2>/dev/null)" || die "cannot resolve source"

case "$SOURCE" in
    "$ROOT/protein/00-core"|"$ROOT/protein/00-core"/*)
        die "source is CORE"
        ;;
    "$ROOT/protein/05-validator"|"$ROOT/protein/05-validator"/*)
        die "source is VALIDATOR"
        ;;
    "$ROOT/protein/08-cleaner"|"$ROOT/protein/08-cleaner"/*)
        die "source is CLEANER"
        ;;
    "$ROOT/protein/10-governor"|"$ROOT/protein/10-governor"/*)
        die "source is GOVERNOR"
        ;;
    "$ROOT/protein/11-molecules"|"$ROOT/protein/11-molecules"/*)
        die "source is MOLECULES"
        ;;
    "$ROOT/protein/12-runtime/state"|"$ROOT/protein/12-runtime/state"/*)
        die "source is RUNTIME STATE"
        ;;
esac

case "$SOURCE" in
    "$ROOT/expansion/incoming"|"$ROOT/expansion/incoming"/*)
        ;;
    *)
        die "source is outside admission boundary"
        ;;
esac

if [[ -L "$1" ]]; then
    TARGET="$(realpath "$1" 2>/dev/null)" || die "broken symlink"
    case "$TARGET" in
        "$ROOT/expansion/incoming"|"$ROOT/expansion/incoming"/*)
            ;;
        *)
            die "symlink escapes admission boundary: $TARGET"
            ;;
    esac
fi

print -- "ADMISSION SAFE FOR REVIEW"
print -- "SOURCE=$SOURCE"
print -- "BOUNDARY=$ROOT/expansion/incoming"
print -- "ACTION=REVIEW_ONLY"
print -- "NO_IMPORT_PERFORMED"
exit 0
