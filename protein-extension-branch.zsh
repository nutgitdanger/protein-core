#!/usr/bin/env zsh

setopt NO_NOMATCH
setopt PIPE_FAIL

R="$HOME/.config/dynu-audit/protein"
NOW="$(date +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/extension-branch-$NOW"

mkdir -p "$OUT"

echo '============================================================'
echo ' PROTEIN V2 — EXTENSION BRANCHING'
echo '============================================================'
echo "RUN=$NOW"
echo "OUTPUT=$OUT"

echo
echo '[1] SAFETY'
cat > "$OUT/safety.state" <<EOF
MODE=ANALYSIS_ONLY
SOURCE_MUTATION=NO
DELETE=NO
MOVE=NO
QUARANTINE=NO
KILL=NO
EXTERNAL_WRITE=NO
CREDENTIAL_READ=NO
EOF
cat "$OUT/safety.state"

echo
echo '[2] SOURCE ROOTS'
{
    echo "HOME=$HOME"
    echo "TERMUX_PACKAGES=$HOME/termux-packages"
    echo "PROTEIN_ROOT=$R"
} | tee "$OUT/sources.state"

echo
echo '[3] EXTENSION CLASSIFICATION'

typeset -A count

classify_ext() {
    local f="$1"
    local base="${f:t}"
    local ext="${base:e}"

    if [[ "$base" == .* && "$base" != *.* ]]; then
        echo "NO_EXTENSION"
        return
    fi

    if [[ -z "$ext" ]]; then
        echo "NO_EXTENSION"
        return
    fi

    ext="${ext:l}"

    case "$ext" in
        sh|zsh|bash|fish)
            echo "SHELL"
            ;;
        json|yaml|yml)
            echo "STRUCTURED_DATA"
            ;;
        md|markdown|txt|rst)
            echo "DOCUMENTATION"
            ;;
        js|mjs|cjs|ts|tsx|jsx)
            echo "JAVASCRIPT_RUNTIME"
            ;;
        py|py3)
            echo "PYTHON"
            ;;
        c|h|cc|cpp|cxx|hpp)
            echo "NATIVE_SOURCE"
            ;;
        toml|ini|conf|cfg)
            echo "CONFIGURATION"
            ;;
        xml)
            echo "XML_DATA"
            ;;
        html|htm|css)
            echo "WEB"
            ;;
        sql)
            echo "DATABASE"
            ;;
        lock)
            echo "LOCKFILE"
            ;;
        service|socket|timer)
            echo "SYSTEM_UNIT"
            ;;
        *)
            echo "OTHER"
            ;;
    esac
}

scan_root() {
    local root="$1"
    local name="$2"
    local index="$OUT/$name.extensions.tsv"

    echo -e "CLASS\tEXTENSION\tCOUNT" > "$index"

    find "$root" -type f -print0 2>/dev/null |
    while IFS= read -r -d '' f; do
        local base="${f:t}"
        local ext="${base:e}"

        if [[ "$base" == .* && "$base" != *.* ]]; then
            ext="[none]"
        elif [[ -z "$ext" ]]; then
            ext="[none]"
        else
            ext="${ext:l}"
            ext=".$ext"
        fi

        local cls="$(classify_ext "$f")"
        echo "$cls"$'\t'"$ext"
    done |
    sort |
    uniq -c |
    awk '{print $2 "\t" $3 "\t" $1}' |
    sort -k1,1 -k2,2 >> "$index"

    echo "$index"
}

echo
echo '[4] TERMUX PACKAGE TREE'

if [[ -d "$HOME/termux-packages" ]]; then
    scan_root "$HOME/termux-packages" "termux-packages"
    echo "TERMUX_BRANCH=CREATED"
else
    echo "TERMUX_BRANCH=NOT_FOUND"
fi

echo
echo '[5] HOME DATA'

scan_root "$HOME" "home"

echo
echo '[6] BRANCH SUMMARY'

{
    echo "=== TERMUX-PACKAGES ==="
    if [[ -f "$OUT/termux-packages.extensions.tsv" ]]; then
        cat "$OUT/termux-packages.extensions.tsv"
    fi

    echo
    echo "=== HOME ==="
    cat "$OUT/home.extensions.tsv"
} > "$OUT/branch-summary.txt"

cat "$OUT/branch-summary.txt"

echo
echo '[7] MOLECULE CANDIDATES'

cat > "$OUT/molecules.state" <<EOF
SHELL_MOLECULE=DISCOVERED
STRUCTURED_DATA_MOLECULE=DISCOVERED
DOCUMENTATION_MOLECULE=DISCOVERED
JAVASCRIPT_RUNTIME_MOLECULE=DISCOVERED
PYTHON_MOLECULE=DISCOVERED
NATIVE_SOURCE_MOLECULE=DISCOVERED
CONFIGURATION_MOLECULE=DISCOVERED
WEB_MOLECULE=DISCOVERED
DATABASE_MOLECULE=DISCOVERED
LOCKFILE_MOLECULE=DISCOVERED
SYSTEM_UNIT_MOLECULE=DISCOVERED
OTHER_MOLECULE=DISCOVERED
NO_EXTENSION_MOLECULE=DISCOVERED
EOF

cat "$OUT/molecules.state"

echo
echo '[8] LINEAGE'

cat > "$OUT/lineage.state" <<EOF
ROOT=DNA
PARENT=PROTEIN
GENERATION=EXTENSION_BRANCH
SOURCE=EXISTING_DATA
RIGHTS=INHERITED_ONLY
SOURCE_FILES_MOVED=NO
SOURCE_FILES_DELETED=NO
DNA_MUTATION=NO
EOF

cat "$OUT/lineage.state"

echo
echo '[9] CHECKPOINT'

cat > "$OUT/checkpoint.json" <<EOF
{
  "run": "$NOW",
  "mode": "ANALYSIS_ONLY",
  "operation": "EXTENSION_BRANCHING",
  "source_mutation": false,
  "delete": false,
  "move": false,
  "quarantine": false,
  "kill": false,
  "external_write": false,
  "dna_mutation": false,
  "rights": "inherited_only"
}
EOF

cat "$OUT/checkpoint.json"

echo
echo '============================================================'
echo ' EXTENSION BRANCHING COMPLETE'
echo '============================================================'
echo "CHECKPOINT=$OUT"
echo 'RESULT=ANALYSIS_ONLY'
echo 'SOURCE=UNCHANGED'
echo '============================================================'
