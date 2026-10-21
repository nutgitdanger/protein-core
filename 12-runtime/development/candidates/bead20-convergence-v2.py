#!/usr/bin/env python3

import json
import math
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"

SRC = (
    ROOT
    / "protein/12-runtime/development/evidence/"
      "bead20-normalization-result.json"
)

OUT = (
    ROOT
    / "protein/12-runtime/development/evidence/"
      "bead20-convergence-v2-result.json"
)

data = json.loads(SRC.read_text())

pairs = data.get("PAIRWISE", [])

values = []

for pair in pairs:
    value = pair.get("RMSD_ROTATION_ALIGNED")

    if isinstance(value, (int, float)) and math.isfinite(value):
        values.append(float(value))

runs = data.get("NORMALIZED_RUNS", 0)
comparisons = data.get("PAIR_COMPARISONS", 0)
rotation = data.get("ROTATION_ALIGNMENT", False)

if values:
    average = sum(values) / len(values)
    minimum = min(values)
    maximum = max(values)
else:
    average = None
    minimum = None
    maximum = None

valid = (
    runs >= 2
    and comparisons > 0
    and len(values) == comparisons
    and average is not None
    and rotation is True
)

result = {
    "RESULT": "PASS" if valid else "FAIL",
    "MODE": "CONVERGENCE_V2",
    "RUNS": runs,
    "PAIR_COMPARISONS": comparisons,
    "VALID_RMSD_VALUES": len(values),
    "AVERAGE_RMSD": average,
    "MIN_RMSD": minimum,
    "MAX_RMSD": maximum,
    "ROTATION_ALIGNED": bool(rotation),
    "CONVERGENCE_STATUS": (
        "MEASURED_NOT_YET_CLASSIFIED"
        if valid
        else "INSUFFICIENT_DATA"
    )
}

OUT.write_text(json.dumps(result, indent=2))

print(json.dumps(result, indent=2))
print(f"EVIDENCE={OUT}")

raise SystemExit(0 if valid else 1)
