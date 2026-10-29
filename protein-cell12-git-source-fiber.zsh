#!/data/data/com.termux/files/usr/bin/zsh

export PATH="$PREFIX/bin:$HOME/bin:/system/bin:/system/xbin"
R="$HOME/.config/dynu-audit/protein"
SRC="$HOME/termux-packages/packages"
RUN="$("$PREFIX/bin/date" +%Y%m%d-%H%M%S)"
OUT="$R/02-collector/checkpoints/cell12-git-source-fiber-$RUN"

mkdir -p \
  "$OUT/01-input" \
  "$OUT/02-source" \
  "$OUT/03-dependencies" \
  "$OUT/04-capabilities" \
  "$OUT/05-fibers" \
  "$OUT/06-molecules" \
  "$OUT/07-unresolved" \
  "$OUT/08-verification"

echo 'PACKAGE	VERSION' > "$OUT/01-input/installed.tsv"

"$PREFIX/bin/dpkg-query" -W -f='${binary:Package}\t${Version}\n' 2>/dev/null |
"$PREFIX/bin/grep" -Ev '^(git|git-|gh)(:|$|[[:space:]])' |
"$PREFIX/bin/sort" >> "$OUT/01-input/installed.tsv"

echo 'PACKAGE	VERSION	STATUS	SOURCE' > "$OUT/02-source/package.tsv"
echo 'PACKAGE	SOURCE	DEPENDENCY_FIELD	DEPENDENCY' > "$OUT/03-dependencies/dependencies.tsv"
echo 'PACKAGE	CAPABILITY	SOURCE	CONFIDENCE' > "$OUT/04-capabilities/capabilities.tsv"
echo 'PACKAGE	SOURCE	FIBER_TYPE	FIBER' > "$OUT/05-fibers/fibers.tsv"
echo 'PACKAGE	REASON' > "$OUT/07-unresolved/unresolved.tsv"

DIRECT=0
UNRESOLVED=0
DEP=0
CAP=0
FIBER=0

while IFS=$'\t' read -r PKG VER; do
    [[ "$PKG" == "PACKAGE" ]] && continue
    [[ -z "$PKG" ]] && continue

    BASE="${PKG%%:*}"
    SOURCE="$SRC/$BASE/build.sh"

    if [[ -f "$SOURCE" ]]; then
        echo "$BASE	$VER	DIRECT	$SOURCE" \
          >> "$OUT/02-source/package.tsv"

        echo "$BASE	SOURCE_DEFINITION	$SOURCE	STRONG" \
          >> "$OUT/04-capabilities/capabilities.tsv"

        echo "$BASE	$SOURCE	SOURCE	$BASE" \
          >> "$OUT/05-fibers/fibers.tsv"

        DIRECT=$((DIRECT+1))
        CAP=$((CAP+1))
        FIBER=$((FIBER+1))
    else
        echo "$BASE	$VER	UNRESOLVED	" \
          >> "$OUT/02-source/package.tsv"

        echo "$BASE	NO_EXACT_BUILD_DEFINITION" \
          >> "$OUT/07-unresolved/unresolved.tsv"

        UNRESOLVED=$((UNRESOLVED+1))
    fi
done < "$OUT/01-input/installed.tsv"

# Dependency fiber from discovered build definitions
while IFS=$'\t' read -r PKG VER STATUS SOURCE; do
    [[ "$STATUS" != "DIRECT" ]] && continue
    [[ -z "$SOURCE" ]] && continue

    for FIELD in TERMUX_PKG_DEPENDS TERMUX_PKG_BUILD_DEPENDS \
                 TERMUX_PKG_RECOMMENDS TERMUX_PKG_SUGGESTS; do

        LINE="$("$PREFIX/bin/grep" -E "^${FIELD}=" "$SOURCE" 2>/dev/null | "$PREFIX/bin/head" -1)"
        [[ -z "$LINE" ]] && continue

        VALUE="${LINE#*=}"
        VALUE="${VALUE#\"}"
        VALUE="${VALUE%\"}"

        for D in ${(s: :)VALUE}; do
            D="${D%%:*}"
            D="${D%%[<>=]*}"
            [[ -z "$D" ]] && continue

            echo "$PKG	$SOURCE	$FIELD	$D" \
              >> "$OUT/03-dependencies/dependencies.tsv"

            echo "$PKG	DEPENDENCY:$D	$SOURCE	MEDIUM" \
              >> "$OUT/04-capabilities/capabilities.tsv"

            echo "$PKG	$SOURCE	DEPENDENCY	$D" \
              >> "$OUT/05-fibers/fibers.tsv"

            DEP=$((DEP+1))
            CAP=$((CAP+1))
            FIBER=$((FIBER+1))
        done
    done
done < "$OUT/02-source/package.tsv"

# Molecule summary
echo 'MOLECULE	PACKAGES	CAPABILITIES	STATUS' \
  > "$OUT/06-molecules/molecules.tsv"

echo "RUNTIME_DIRECT	$DIRECT	$CAP	ACTIVE" \
  >> "$OUT/06-molecules/molecules.tsv"

echo "RUNTIME_UNRESOLVED	$UNRESOLVED	0	REVIEW" \
  >> "$OUT/06-molecules/molecules.tsv"

echo "DEPENDENCY_FIBER	$DEP	$DEP	ACTIVE" \
  >> "$OUT/06-molecules/molecules.tsv"

INSTALLED_COUNT=$("$PREFIX/bin/wc" -l < "$OUT/01-input/installed.tsv")
INSTALLED_COUNT=$((INSTALLED_COUNT - 1))
# Safety
cat > "$OUT/01-input/safety.tsv" <<EOF
PACKAGE_INSTALL	NO
PACKAGE_DELETE	NO
APT_WRITE	NO
GIT_WRITE	NO
DNA_MUTATION	NO
SOURCE_MODIFY	NO
CREDENTIAL_READ	NO
EXTERNAL_WRITE	NO
EOF

FAIL_COUNT=0
[[ -d "$SRC" ]] || FAIL_COUNT=$((FAIL_COUNT + 1))
[[ -s "$OUT/01-input/installed.tsv" ]] || FAIL_COUNT=$((FAIL_COUNT + 1))
[[ -s "$OUT/02-source/package.tsv" ]] || FAIL_COUNT=$((FAIL_COUNT + 1))
cat > "$OUT/08-verification/result.tsv" <<EOF
RESULT	CELL_12_PENDING
INSTALLED_EX_GIT	${INSTALLED_COUNT}
DIRECT_SOURCE	$DIRECT
UNRESOLVED	$UNRESOLVED
DEPENDENCY_RECORDS	$DEP
CAPABILITY_RECORDS	$CAP
FIBER_RECORDS	$FIBER
PACKAGE_INSTALL	NO
PACKAGE_DELETE	NO
APT_WRITE	NO
GIT_WRITE	NO
DNA_MUTATION	NO
SOURCE_MODIFY	NO
CREDENTIAL_READ	NO
EXTERNAL_WRITE	NO
RIGHTS	INHERITED_ONLY
NEXT	CELL_13
EOF

cat > "$OUT/08-verification/lineage.tsv" <<EOF
ROOT	DNA_ROOT
PARENT	PROTEIN
GENERATION	CELL_12
SOURCE_RUNTIME	156_EXCLUDING_GIT
SOURCE_CATALOG	LOCAL_TERMUX_PACKAGES
RESULT	CELL_12_PENDING
RIGHTS	INHERITED_ONLY
EOF

echo
echo '=== CELL 12 RESULT ==='
"$PREFIX/bin/cat" "$OUT/08-verification/result.tsv"
echo
echo "CHECKPOINT=$OUT"
