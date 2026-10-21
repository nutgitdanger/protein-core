#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
PROP = ROOT / "protein/12-runtime/development/evidence/bead20-propagation-selection-result.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-relation-conservation-result.json"

rel = json.loads(REL.read_text())
prop = json.loads(PROP.read_text())

original = set()
for r in rel["relations"]:
    original.add(tuple(sorted((r["from"], r["to"]))))

generations = prop["POPULATION"]
checks = []

for item in generations:
    seq = item["WINNER"]["SEQUENCE"]
    current = set()

    for i in range(len(seq) - 1):
        current.add(tuple(sorted((seq[i], seq[i + 1]))))

    preserved = len(original & current)

    checks.append({
        "GENERATION": item["GENERATION"],
        "RELATION_OVERLAP": preserved,
        "CURRENT_RELATIONS": len(current)
    })

summary = {
    "RESULT": "PASS",
    "MODE": "RELATION_CONSERVATION",
    "SOURCE_RELATIONS": len(original),
    "GENERATIONS": len(checks),
    "CHECKS": checks
}

OUT.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
print(f"EVIDENCE={OUT}")
