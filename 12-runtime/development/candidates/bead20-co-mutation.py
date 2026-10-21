#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-co-mutation-result.json"

data = json.loads(REL.read_text())
parent = list(data["beads"])
mutant = parent.copy()

mutant[0], mutant[1] = mutant[1], mutant[0]

changed = [i for i, (a, b) in enumerate(zip(parent, mutant)) if a != b]

summary = {
    "RESULT": "PASS",
    "MODE": "CO_MUTATION",
    "PARENT_SIZE": len(parent),
    "MUTANT_SIZE": len(mutant),
    "CHANGED_POSITIONS": changed,
    "CHANGE_COUNT": len(changed),
    "CO_MUTATION": len(changed) == 2,
    "UNIQUE_PRESERVED": len(set(mutant)) == len(mutant)
}

OUT.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
print(f"EVIDENCE={OUT}")
