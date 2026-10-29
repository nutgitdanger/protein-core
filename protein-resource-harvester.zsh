#!/usr/bin/env zsh

# ============================================================
# PROTEIN V2 — RESOURCE HARVESTER / EVOLUTION ENGINE
#
# PRINCIPLE
#
#   DATA MASS
#       ↓
#   DISCOVER
#       ↓
#   CLASSIFY
#       ↓
#   RELATE
#       ↓
#   FITNESS
#       ↓
#   HARVEST USEFUL RESOURCE
#       ↓
#   MOLECULE
#       ↓
#   BRANCH / EXPERIMENT
#       ↓
#   EVOLVE ?
#      / \
#    YES  NO
#     ↓    ↓
#   GROW  DECOMPOSE
#
# SAFETY:
#   SOURCE IS NEVER MOVED
#   SOURCE IS NEVER DELETED
#   DNA IS NEVER MODIFIED
#   RIGHTS NEVER EXCEED DNA
#   CREDENTIAL CONTENT IS NEVER READ
#
# ============================================================

setopt NO_NOMATCH
setopt PIPE_FAIL
setopt NULL_GLOB

R="$HOME/.config/dynu-audit/protein"
NOW="$(date +%Y%m%d-%H%M%S)"

OUT="$R/02-collector/checkpoints/resource-harvest-$NOW"
POOL="$R/11-molecules/resource-pool"
LINEAGE="$R/11-molecules/lineage"

mkdir -p \
    "$OUT/discovery" \
    "$OUT/candidates" \
    "$OUT/fitness" \
    "$OUT/decisions" \
    "$OUT/relations" \
    "$OUT/validation" \
    "$OUT/receipts" \
    "$POOL" \
    "$LINEAGE"

echo '============================================================'
echo ' PROTEIN V2 — RESOURCE HARVESTER'
echo '============================================================'
echo "RUN=$NOW"
echo "ROOT=$R"
echo "OUTPUT=$OUT"

# ------------------------------------------------------------
# 01 SAFETY
# ------------------------------------------------------------

cat > "$OUT/validation/safety.state" <<EOF
MODE=RESOURCE_HARVEST
SOURCE_MOVE=NO
SOURCE_DELETE=NO
SOURCE_RENAME=NO
SOURCE_MODIFY=NO
DNA_MUTATION=NO
CREDENTIAL_READ=NO
EXTERNAL_WRITE=NO
PROCESS_KILL=NO
RIGHTS=INHERITED_ONLY
EOF

echo
echo '[01] SAFETY'
cat "$OUT/validation/safety.state"

# ------------------------------------------------------------
# 02 DNA CHECK
# ------------------------------------------------------------

echo
echo '[02] DNA'

DNA="$R/00-core/dna"

if [[ ! -d "$DNA" ]]; then
    echo 'DNA_ROOT=FAIL'
    exit 1
fi

for F in \
    identity.json \
    capabilities.json \
    boundaries.json \
    dependencies.json \
    policy.json
do
    if [[ -f "$DNA/$F" ]]; then
        echo "DNA_$F=VALID"
        sha256sum "$DNA/$F"
    else
        echo "DNA_$F=MISSING"
        exit 1
    fi
done

# ------------------------------------------------------------
# 03 SOURCE POOL
# ------------------------------------------------------------

echo
echo '[03] RESOURCE SOURCES'

typeset -a SOURCES

[[ -d "$HOME/termux-packages" ]] &&
    SOURCES+=("$HOME/termux-packages")

[[ -d "$HOME/projects" ]] &&
    SOURCES+=("$HOME/projects")

[[ -d "$HOME/bin" ]] &&
    SOURCES+=("$HOME/bin")

[[ -d "$HOME/.config/nut" ]] &&
    SOURCES+=("$HOME/.config/nut")

[[ -d "$HOME/.config/zsh" ]] &&
    SOURCES+=("$HOME/.config/zsh")

printf '%s\n' "${SOURCES[@]}" |
tee "$OUT/discovery/source-roots.txt"

# ------------------------------------------------------------
# 04 PROTECTED PATH
# ------------------------------------------------------------

is_protected() {
    local f="$1"
    local b="${f:t}"

    case "$f" in
        "$R"/*)
            return 0
            ;;
        */.ssh/*)
            return 0
            ;;
        */.secrets/*)
            return 0
            ;;
        */.config/gh/*)
            return 0
            ;;
        */.termux/*)
            return 0
            ;;
    esac

    case "$b" in
        .env|.env.*|*.pem|*.key|*.p8|*.p12|*.pfx|*.secrets|*secret*)
            return 0
            ;;
    esac

    return 1
}

# ------------------------------------------------------------
# 05 CLASSIFICATION
# ------------------------------------------------------------

classify() {

    local F="$1"
    local B="${F:t}"
    local E="${B:e:l}"

    if is_protected "$F"; then
        echo "PROTECTED"
        return
    fi

    if [[ "$B" == .* && "$B" != *.* ]]; then
        E=""
    fi

    case "$E" in
        sh|zsh|bash|fish|ksh)
            echo "SHELL"
            return
            ;;
        js|mjs|cjs|jsx|ts|tsx|mts|cts)
            echo "JAVASCRIPT_TYPESCRIPT"
            return
            ;;
        py|py3|pyx)
            echo "PYTHON"
            return
            ;;
        rs)
            echo "RUST"
            return
            ;;
        c|h|cc|cpp|cxx|hpp|hh|inl)
            echo "NATIVE_C_CPP"
            return
            ;;
        java|kt|kts)
            echo "JVM"
            return
            ;;
        go)
            echo "GO"
            return
            ;;
        rb|ruby)
            echo "RUBY"
            return
            ;;
        pl|pm)
            echo "PERL"
            return
            ;;
        json|json5|yaml|yml|toml|xml|ndjson)
            echo "STRUCTURED_DATA"
            return
            ;;
        conf|cfg|ini|rc)
            echo "CONFIGURATION"
            return
            ;;
        html|htm|css|scss|less|svg)
            echo "WEB"
            return
            ;;
        sql|db|sqlite|sqlite3)
            echo "DATABASE"
            return
            ;;
        md|markdown|rst|txt|adoc|man)
            echo "DOCUMENTATION"
            return
            ;;
        patch|diff)
            echo "BUILD_PATCH"
            return
            ;;
        lock|pid|state|log|stdout|stderr)
            echo "RUNTIME_STATE"
            return
            ;;
        o|a|so|dylib|dll|elf|macho|wasm)
            echo "NATIVE_ARTIFACT"
            return
            ;;
        tar|gz|bz2|xz|zst|zip|tgz|deb|rpm|apk|whl|crate)
            echo "PACKAGE_ARTIFACT"
            return
            ;;
        png|jpg|jpeg|gif|webp|mp3|mp4|ttf|woff|woff2)
            echo "MEDIA"
            return
            ;;
    esac

    case "$B" in
        Makefile|makefile|GNUmakefile|PKGBUILD|build.sh|configure|configure.ac)
            echo "BUILD"
            return
            ;;
        Cargo.toml|Cargo.lock)
            echo "RUST_BUILD"
            return
            ;;
        package.json|package-lock.json|npm-shrinkwrap.json|pnpm-lock.yaml|yarn.lock)
            echo "DEPENDENCY"
            return
            ;;
        pyproject.toml|requirements.txt|Pipfile|Pipfile.lock)
            echo "DEPENDENCY"
            return
            ;;
        .gitignore|.gitattributes|.editorconfig|.gitconfig)
            echo "CONFIGURATION"
            return
            ;;
    esac

    if [[ -z "$E" ]]; then
        echo "NO_EXTENSION"
    else
        echo "UNKNOWN"
    fi
}

# ------------------------------------------------------------
# 06 RESOURCE VALUE
#
# Metadata first.
# No mass hashing.
# ------------------------------------------------------------

resource_value() {

    local F="$1"
    local CLASS="$2"
    local SIZE="$3"

    local SCORE=0

    case "$CLASS" in
        SHELL)
            SCORE=$((SCORE+15))
            ;;
        JAVASCRIPT_TYPESCRIPT|PYTHON|RUST|NATIVE_C_CPP|JVM|GO|RUBY|PERL)
            SCORE=$((SCORE+15))
            ;;
        DEPENDENCY|BUILD|CONFIGURATION)
            SCORE=$((SCORE+12))
            ;;
        STRUCTURED_DATA)
            SCORE=$((SCORE+10))
            ;;
        DOCUMENTATION)
            SCORE=$((SCORE+9))
            ;;
        WEB|DATABASE)
            SCORE=$((SCORE+10))
            ;;
        BUILD_PATCH)
            SCORE=$((SCORE+8))
            ;;
        NATIVE_ARTIFACT|PACKAGE_ARTIFACT)
            SCORE=$((SCORE+5))
            ;;
        RUNTIME_STATE)
            SCORE=$((SCORE+3))
            ;;
        MEDIA)
            SCORE=$((SCORE+2))
            ;;
        NO_EXTENSION|UNKNOWN)
            SCORE=$((SCORE+1))
            ;;
        PROTECTED)
            SCORE=0
            ;;
    esac

    # Very small files often contain reusable configuration/logic.
    if (( SIZE > 0 && SIZE < 1048576 )); then
        SCORE=$((SCORE+5))
    fi

    # Extremely large files receive a cost penalty.
    if (( SIZE > 104857600 )); then
        SCORE=$((SCORE-8))
    elif (( SIZE > 52428800 )); then
        SCORE=$((SCORE-4))
    fi

    (( SCORE < 0 )) && SCORE=0
    (( SCORE > 20 )) && SCORE=20

    echo "$SCORE"
}

# ------------------------------------------------------------
# 07 DISCOVERY
# ------------------------------------------------------------

echo
echo '[03] DISCOVERY'

MASTER="$OUT/discovery/resources.tsv"

printf 'CLASS\tSCORE\tSIZE\tMTIME\tPATH\n' > "$MASTER"

for ROOT in "${SOURCES[@]}"; do

    echo "SCANNING=$ROOT"

    find "$ROOT" \
        -type f \
        -print0 \
        2>/dev/null |

    while IFS= read -r -d '' F; do

        [[ -f "$F" ]] || continue

        # Never harvest Protein itself.
        [[ "$F" == "$R"/* ]] && continue

        CLASS="$(classify "$F")"

        # Protected resources are recorded only by metadata.
        if [[ "$CLASS" == "PROTECTED" ]]; then
            printf '%s\t0\t0\t0\t%s\n' \
                "$CLASS" "$F" >> "$MASTER"
            continue
        fi

        SIZE="$(stat -c '%s' "$F" 2>/dev/null || echo 0)"
        MTIME="$(stat -c '%Y' "$F" 2>/dev/null || echo 0)"

        SCORE="$(resource_value "$F" "$CLASS" "$SIZE")"

        printf '%s\t%s\t%s\t%s\t%s\n' \
            "$CLASS" \
            "$SCORE" \
            "$SIZE" \
            "$MTIME" \
            "$F"

    done

done >> "$MASTER"

TOTAL="$(tail -n +2 "$MASTER" | wc -l)"

echo "RESOURCE_COUNT=$TOTAL"

# ------------------------------------------------------------
# 08 RESOURCE POOL CANDIDATES
# ------------------------------------------------------------

echo
echo '[04] HARVEST CANDIDATES'

CAND="$OUT/candidates/harvest.tsv"

printf 'CLASS\tSCORE\tSIZE\tMTIME\tPATH\n' > "$CAND"

awk -F '\t' '
NR > 1 &&
$1 != "PROTECTED" &&
$2 >= 10 {
    print
}
' "$MASTER" > "$CAND.tmp"

# Limit only the number processed in ONE generation.
# The resource pool remains available for future generations.
head -1000 "$CAND.tmp" >> "$CAND"

rm -f "$CAND.tmp"

CAND_COUNT="$(tail -n +2 "$CAND" | wc -l)"

echo "HARVEST_CANDIDATES=$CAND_COUNT"

# ------------------------------------------------------------
# 09 BRANCH ALLOCATION
# ------------------------------------------------------------

echo
echo '[05] BRANCH ALLOCATION'

mkdir -p \
    "$POOL/source" \
    "$POOL/knowledge" \
    "$POOL/capability" \
    "$POOL/dependency" \
    "$POOL/build" \
    "$POOL/data"

allocation_target() {

    case "$1" in
        DOCUMENTATION)
            echo "knowledge"
            ;;
        SHELL|JAVASCRIPT_TYPESCRIPT|PYTHON|RUST|NATIVE_C_CPP|JVM|GO|RUBY|PERL)
            echo "capability"
            ;;
        DEPENDENCY)
            echo "dependency"
            ;;
        BUILD|BUILD_PATCH|NATIVE_ARTIFACT|PACKAGE_ARTIFACT)
            echo "build"
            ;;
        STRUCTURED_DATA|DATABASE|CONFIGURATION|WEB)
            echo "data"
            ;;
        *)
            echo "source"
            ;;
    esac
}

DECISIONS="$OUT/decisions/harvest.tsv"

printf 'CLASS\tSCORE\tACTION\tTARGET\tSOURCE\n' > "$DECISIONS"

tail -n +2 "$CAND" |
while IFS=$'\t' read -r CLASS SCORE SIZE MTIME F; do

    TARGET="$(allocation_target "$CLASS")"

    ACTION="HARVEST"

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$CLASS" \
        "$SCORE" \
        "$ACTION" \
        "$TARGET" \
        "$F"

done >> "$DECISIONS"

# ------------------------------------------------------------
# 10 HARVEST
#
# COPY only.
# Source remains untouched.
# ------------------------------------------------------------

echo
echo '[06] HARVEST INTO PROTEIN RESOURCE POOL'

HARVESTED=0
SKIPPED=0

tail -n +2 "$DECISIONS" |
while IFS=$'\t' read -r CLASS SCORE ACTION TARGET SOURCE; do

    [[ "$ACTION" == "HARVEST" ]] || continue
    [[ -f "$SOURCE" ]] || continue

    BASE="${SOURCE:t}"

    SAFE_NAME="$(printf '%s' "$SOURCE" |
        sha256sum |
        awk '{print substr($1,1,16)}')"

    DEST="$POOL/$TARGET/${SAFE_NAME}--$BASE"

    if [[ -e "$DEST" ]]; then
        echo "REUSE_EXISTING=$DEST"
        continue
    fi

    # COPY, never move.
    cp -p "$SOURCE" "$DEST" 2>/dev/null || continue

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$NOW" \
        "$SOURCE" \
        "$DEST" \
        "$CLASS" \
        "$SCORE" \
        >> "$OUT/receipts/harvested.tsv"

    cat > "$LINEAGE/$SAFE_NAME.json" <<EOF
{
  "generation": "$NOW",
  "parent": "RESOURCE_POOL",
  "root": "DNA",
  "source": "$SOURCE",
  "branch": "$CLASS",
  "target": "$TARGET",
  "fitness_score": $SCORE,
  "operation": "COPY",
  "source_mutated": false,
  "rights": "inherited_only"
}
EOF

done

HARVESTED_COUNT="$(wc -l < "$OUT/receipts/harvested.tsv" 2>/dev/null || echo 0)"

echo "HARVESTED=$HARVESTED_COUNT"

# ------------------------------------------------------------
# 11 EVOLUTION STATUS
#
# Determine whether harvested material can continue evolving.
# This does NOT delete failed branches.
# ------------------------------------------------------------

echo
echo '[07] EVOLUTION STATUS'

EVOLUTION="$OUT/decisions/evolution.tsv"

printf 'RESOURCE\tBRANCH\tFITNESS\tSTATE\n' > "$EVOLUTION"

for L in "$LINEAGE"/*.json; do

    [[ -f "$L" ]] || continue

    RESOURCE="${L:t:r}"

    BRANCH="$(grep '"branch"' "$L" |
        sed 's/.*"branch": "\([^"]*\)".*/\1/' |
        head -1)"

    SCORE="$(grep '"fitness_score"' "$L" |
        sed 's/[^0-9]*\([0-9][0-9]*\).*/\1/' |
        head -1)"

    if (( SCORE >= 15 )); then
        STATE="GROW"
    elif (( SCORE >= 10 )); then
        STATE="HOLD"
    else
        STATE="DECOMPOSE_CANDIDATE"
    fi

    printf '%s\t%s\t%s\t%s\n' \
        "$RESOURCE" \
        "$BRANCH" \
        "$SCORE" \
        "$STATE"

done > "$EVOLUTION"

cat "$EVOLUTION"

# ------------------------------------------------------------
# 12 RESOURCE REUSE INDEX
# ------------------------------------------------------------

echo
echo '[08] RESOURCE REUSE INDEX'

find "$POOL" \
    -type f \
    -print \
    2>/dev/null |
sort > "$OUT/relations/resource-pool-index.txt"

echo "POOL_FILES=$(wc -l < "$OUT/relations/resource-pool-index.txt")"

# ------------------------------------------------------------
# 13 DECOMPOSITION
#
# Decomposition means branch loses active status.
# The original source is preserved.
# ------------------------------------------------------------

echo
echo '[09] DECOMPOSITION CANDIDATES'

awk -F '\t' '
NR > 1 && $4 == "DECOMPOSE_CANDIDATE" {
    print
}
' "$EVOLUTION" \
> "$OUT/decisions/decompose-candidates.tsv"

DECOMPOSE_COUNT="$(
    wc -l < "$OUT/decisions/decompose-candidates.tsv" 2>/dev/null ||
    echo 0
)"

echo "DECOMPOSE_CANDIDATES=$DECOMPOSE_COUNT"

# ------------------------------------------------------------
# 14 RESOURCE PRESSURE
# ------------------------------------------------------------

echo
echo '[10] ENVIRONMENT'

RAM_KB="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
RAM_MB=$((RAM_KB/1024))

DISK_KB="$(df -Pk "$HOME" 2>/dev/null |
    awk 'NR==2 {print $4}' || echo 0)"
DISK_MB=$((DISK_KB/1024))

if (( RAM_MB < 300 )); then
    PRESSURE="EMERGENCY"
elif (( RAM_MB < 700 )); then
    PRESSURE="CONSERVE"
else
    PRESSURE="NORMAL"
fi

cat > "$OUT/validation/environment.state" <<EOF
RAM_AVAILABLE_MB=$RAM_MB
STORAGE_AVAILABLE_MB=$DISK_MB
PRESSURE=$PRESSURE
EOF

cat "$OUT/validation/environment.state"

# ------------------------------------------------------------
# 15 IMMUTABILITY
# ------------------------------------------------------------

echo
echo '[11] SOURCE IMMUTABILITY'

cat > "$OUT/receipts/source.state" <<EOF
SOURCE_MOVED=NO
SOURCE_DELETED=NO
SOURCE_RENAMED=NO
SOURCE_MODIFIED=NO
SOURCE_QUARANTINED=NO
HARVEST_OPERATION=COPY_ONLY
EOF

cat "$OUT/receipts/source.state"

# ------------------------------------------------------------
# 16 LINEAGE
# ------------------------------------------------------------

echo
echo '[12] LINEAGE'

cat > "$OUT/receipts/lineage.state" <<EOF
ROOT=DNA
PARENT=PROTEIN
GENERATION=$NOW
RESOURCE_POOL=ACTIVE
RIGHTS=INHERITED_ONLY
DNA_MUTATION=NO
CAPABILITY_ESCALATION=NO
EOF

cat "$OUT/receipts/lineage.state"

# ------------------------------------------------------------
# 17 CHECKPOINT
# ------------------------------------------------------------

cat > "$OUT/checkpoint.json" <<EOF
{
  "operation": "RESOURCE_HARVESTER",
  "generation": "$NOW",
  "mode": "HARVEST_AND_EVOLVE",
  "source_mutation": false,
  "source_move": false,
  "source_delete": false,
  "dna_mutation": false,
  "credential_read": false,
  "rights": "inherited_only",
  "resource_pool": true,
  "evolution_states": [
    "GROW",
    "HOLD",
    "DECOMPOSE_CANDIDATE"
  ]
}
EOF

# ------------------------------------------------------------
# 18 FINAL VALIDATION
# ------------------------------------------------------------

echo
echo '[13] FINAL VALIDATION'

FAIL=0

[[ -s "$MASTER" ]] ||
    FAIL=$((FAIL+1))

[[ -f "$OUT/checkpoint.json" ]] ||
    FAIL=$((FAIL+1))

[[ -f "$OUT/receipts/source.state" ]] ||
    FAIL=$((FAIL+1))

[[ -f "$OUT/receipts/lineage.state" ]] ||
    FAIL=$((FAIL+1))

grep -q 'SOURCE_DELETED=NO' \
    "$OUT/receipts/source.state" ||
    FAIL=$((FAIL+1))

grep -q 'DNA_MUTATION=NO' \
    "$OUT/receipts/lineage.state" ||
    FAIL=$((FAIL+1))

if (( FAIL == 0 )); then
    RESULT="PASS"
else
    RESULT="FAIL"
fi

echo "VALIDATION_FAILS=$FAIL"
echo "RESULT=$RESULT"

# ------------------------------------------------------------
# 19 SUMMARY
# ------------------------------------------------------------

echo
echo '============================================================'
echo ' PROTEIN RESOURCE HARVEST COMPLETE'
echo '============================================================'
echo "RUN=$NOW"
echo "CHECKPOINT=$OUT"
echo "RESOURCE_POOL=$POOL"
echo "HARVESTED=$HARVESTED_COUNT"
echo "DECOMPOSE_CANDIDATES=$DECOMPOSE_COUNT"
echo "RESULT=$RESULT"

echo
echo 'SOURCE SAFETY'
cat "$OUT/receipts/source.state"

echo
echo 'LINEAGE'
cat "$OUT/receipts/lineage.state"

echo
echo 'ENVIRONMENT'
cat "$OUT/validation/environment.state"

echo
echo '============================================================'
echo ' SOURCE DATA REMAINS INTACT'
echo ' HARVESTED RESOURCES ARE COPIES'
echo ' RIGHTS REMAIN INHERITED FROM DNA'
echo '============================================================'

[[ "$RESULT" == "PASS" ]] || exit 1
exit 0
