#!/usr/bin/env zsh
setopt NO_NOMATCH NULL_GLOB
R="${DYNU_ROOT:-$HOME/.config/dynu-audit}/protein"
POOL="$R/11-molecules/resource-pool"
echo "=== PROTEIN CELL 2 PRECHECK ==="
echo "ROOT=$R"
echo "POOL=$POOL"
[[ -d "$POOL" ]] && echo "POOL=READY" || echo "POOL=NOT_FOUND"
printf "POOL_FILES="; find "$POOL" -type f 2>/dev/null | wc -l
echo "SOURCE_MODIFY=NO"
echo "SOURCE_DELETE=NO"
echo "DNA_MUTATION=NO"
echo "AUTO_DELETE=false"
echo "CELL_2=PRECHECK_ONLY"
