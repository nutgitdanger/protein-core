#!/usr/bin/env zsh

set -u

ROOT="${PROTEIN_ROOT:-${HOME}/.config/dynu-audit}"
POLICY="${ROOT}/protein/00-core/policy/protection.policy"
PROTECTED="${ROOT}/protein/00-core/policy/protected-roots.txt"

die() {
    print -u2 -- "PROTEIN SAFETY GATE: BLOCKED"
    print -u2 -- "$1"
    exit 42
}

[[ -f "$POLICY" ]] || die "policy missing"
[[ -f "$PROTECTED" ]] || die "protected-roots missing"

ACTION="${1:-}"
SOURCE="${2:-}"
TARGET="${3:-}"

[[ -n "$ACTION" ]] || die "action required"
[[ -n "$SOURCE" ]] || die "source required"

case "$ACTION" in
    inspect)
        print -- "SAFE: INSPECTION"
        exit 0
        ;;
    import|merge|overwrite|move|delete)
        ;;
    *)
        die "unknown action: $ACTION"
        ;;
esac

normalize() {
    local p="$1"
    if [[ "$p" = /* ]]; then
        print -r -- "$p"
    else
        print -r -- "${ROOT}/${p}"
    fi
}

SOURCE="$(normalize "$SOURCE")"
[[ -n "$TARGET" ]] && TARGET="$(normalize "$TARGET")"

for root in ${(f)"$(cat "$PROTECTED")"}; do
    protected_path="${ROOT}/${root}"

    case "$SOURCE" in
        "$protected_path"|"$protected_path"/*)
            die "SOURCE IS PROTECTED: $SOURCE"
            ;;
    esac

    if [[ -n "$TARGET" ]]; then
        case "$TARGET" in
            "$protected_path"|"$protected_path"/*)
                die "TARGET IS PROTECTED: $TARGET"
                ;;
        esac
    fi
done

case "$ACTION" in
    import|merge|overwrite|move|delete)
        die "DESTRUCTIVE OR ADMISSION ACTION REQUIRES EXPLICIT REVIEW"
        ;;
esac
