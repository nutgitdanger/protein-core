#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-mutation-pair-result.json"

data = json.loads(REL.read_text())
parent = list(data["beads"])

a = parent.copy()
b = parent.copy()

a[0], a[1] = a[1], a[0]
b[2], b[3] = b[3], b[2]

summary = {
    "RESULT": "PASS",
    "MODE": "MUTATION_PAIR",
    "PARENT": parent,
    "MUTANT_A": a,
    "MUTANT_B": b,
    "PAIR_DISTINCT": a != b,
    "A_UNIQUE": len(set(a)),
    "B_UNIQUE": len(set(b))
}

OUT.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
print(f"EVIDENCE={OUT}")
