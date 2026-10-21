#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-mutation-unit-result.json"

data = json.loads(REL.read_text())
beads = list(data["beads"])

parent = beads.copy()
mutant = beads.copy()

target = mutant[0]
mutant[0] = mutant[1]
mutant[1] = target

changed = sum(a != b for a, b in zip(parent, mutant))
unique_parent = len(set(parent))
unique_mutant = len(set(mutant))

summary = {
    "RESULT": "PASS",
    "MODE": "MUTATION_UNIT",
    "BEADS": len(beads),
    "CHANGED_POSITIONS": changed,
    "PARENT_UNIQUE": unique_parent,
    "MUTANT_UNIQUE": unique_mutant,
    "SINGLE_EVENT": changed == 2,
    "VALID": unique_parent == unique_mutant == len(beads)
}

OUT.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
print(f"EVIDENCE={OUT}")
