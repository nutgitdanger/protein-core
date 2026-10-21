#!/bin/bash

echo "=== 1. Checking Structure and Symlinks ==="
if command -v tree &> /dev/null; then
    tree -F --charset=ascii
else
    find . -maxdepth 4 -print | sed 's;[^/]*/;|____;g;s;____|; |____;g'
fi

echo -e "\n=== 2. Checking Symlinks (Broken Links Check) ==="
find . -type l ! -exec test -e {} \; -print | while read link; do
    echo "[!] Broken Link found (target does not exist): $link"
done

echo "Checking valid symlinks:"
find . -type l -exec ls -l {} +

echo -e "\n=== 3. Checking Executable Permissions ==="
for f in $(find . -name "*.sh"); do
    if [ -x "$f" ]; then
        echo "[OK] Executable: $f"
    else
        echo "[X] Not executable (recommended: chmod +x $f): $f"
    fi
done

echo -e "\n=== 4. Testing AUG-initiation/fold Execution ==="
if [ -x "AUG-initiation/fold" ] || [ -L "AUG-initiation/fold" ]; then
    echo "Attempting to execute starter trigger (dry-run / help check):"
    bash AUG-initiation/fold --help 2>/dev/null || echo "Structure ready, accessible via this path."
else
    echo "[!] AUG-initiation/fold is not directly executable."
fi
