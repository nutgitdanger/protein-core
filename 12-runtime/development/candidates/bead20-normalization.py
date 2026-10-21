#!/usr/bin/env python3

import json
import math
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
SRC = ROOT / "protein/12-runtime/development/evidence/bead20-self-fold-compare-result.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-normalization-result.json"

data = json.loads(SRC.read_text())

runs = data.get("RUNS", [])

def center(points):
    n = len(points)

    if n == 0:
        raise ValueError("EMPTY_STRUCTURE")

    c = [
        sum(p[i] for p in points) / n
        for i in range(3)
    ]

    return [
        [p[i] - c[i] for i in range(3)]
        for p in points
    ]

def dot(a, b):
    return sum(a[i] * b[i] for i in range(3))

def norm(v):
    return math.sqrt(dot(v, v))

def normalize(v):
    n = norm(v)
    if n == 0:
        raise ValueError("ZERO_VECTOR")
    return [x / n for x in v]

def cross(a, b):
    return [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0]
    ]

def mat_vec(m, v):
    return [
        sum(m[i][j] * v[j] for j in range(4))
        for i in range(4)
    ]

def quaternion_rotation(q):
    w, x, y, z = q

    return [
        [
            1 - 2 * (y*y + z*z),
            2 * (x*y - z*w),
            2 * (x*z + y*w)
        ],
        [
            2 * (x*y + z*w),
            1 - 2 * (x*x + z*z),
            2 * (y*z - x*w)
        ],
        [
            2 * (x*z - y*w),
            2 * (y*z + x*w),
            1 - 2 * (x*x + y*y)
        ]
    ]

def apply_rotation(points, rotation):
    return [
        [
            sum(rotation[i][j] * p[j] for j in range(3))
            for i in range(3)
        ]
        for p in points
    ]

def horn_matrix(a, b):
    sxx = syx = szx = 0.0
    sxy = syy = szy = 0.0
    sxz = syz = szz = 0.0

    for pa, pb in zip(a, b):
        ax, ay, az = pa
        bx, by, bz = pb

        sxx += ax * bx
        sxy += ax * by
        sxz += ax * bz

        syx += ay * bx
        syy += ay * by
        syz += ay * bz

        szx += az * bx
        szy += az * by
        szz += az * bz

    return [
        [
            sxx + syy + szz,
            syz - szy,
            szx - sxz,
            sxy - syx
        ],
        [
            syz - szy,
            sxx - syy - szz,
            sxy + syx,
            szx + sxz
        ],
        [
            szx - sxz,
            sxy + syx,
            -sxx + syy - szz,
            syz + szy
        ],
        [
            sxy - syx,
            szx + sxz,
            syz + szy,
            -sxx - syy + szz
        ]
    ]

def largest_eigenvector(matrix):
    q = [1.0, 0.0, 0.0, 0.0]

    for _ in range(100):
        nq = mat_vec(matrix, q)
        length = math.sqrt(sum(x*x for x in nq))

        if length == 0:
            raise ValueError("EIGENVECTOR_FAILURE")

        nq = [x / length for x in nq]

        delta = math.sqrt(
            sum((nq[i] - q[i]) ** 2 for i in range(4))
        )

        q = nq

        if delta < 1e-12:
            break

    return q

def aligned_rmsd(reference, target):
    if len(reference) != len(target):
        raise ValueError("POINT_COUNT_MISMATCH")

    a = center(reference)
    b = center(target)

    matrix = horn_matrix(b, a)
    q = largest_eigenvector(matrix)

    q = normalize(q)
    rotation = quaternion_rotation(q)

    aligned = apply_rotation(b, rotation)

    return math.sqrt(
        sum(
            sum(
                (aligned[i][j] - a[i][j]) ** 2
                for j in range(3)
            )
            for i in range(len(a))
        ) / len(a)
    )

normalized = []
errors = []

for index, run in enumerate(runs):
    positions = run.get("positions")

    if not isinstance(positions, dict):
        errors.append({
            "RUN": index,
            "STATUS": "NO_POSITIONS"
        })
        continue

    names = list(data["RUNS"][0]["positions"].keys())

    if set(positions.keys()) != set(names):
        errors.append({
            "RUN": index,
            "STATUS": "BEAD_SET_MISMATCH"
        })
        continue

    points = [positions[name] for name in names]

    if len(points) != 20:
        errors.append({
            "RUN": index,
            "STATUS": "BEAD_COUNT_INVALID",
            "COUNT": len(points)
        })
        continue

    centered = center(points)

    normalized.append({
        "RUN": index,
        "SEED": run["seed"],
        "BEADS": len(points),
        "CENTERED": centered
    })

pairwise = []

for i in range(len(normalized)):
    for j in range(i + 1, len(normalized)):
        rmsd_value = aligned_rmsd(
            normalized[i]["CENTERED"],
            normalized[j]["CENTERED"]
        )

        pairwise.append({
            "A": normalized[i]["RUN"],
            "B": normalized[j]["RUN"],
            "SEED_A": normalized[i]["SEED"],
            "SEED_B": normalized[j]["SEED"],
            "RMSD_ROTATION_ALIGNED": rmsd_value
        })

if pairwise:
    average = sum(x["RMSD_ROTATION_ALIGNED"] for x in pairwise) / len(pairwise)
    minimum = min(x["RMSD_ROTATION_ALIGNED"] for x in pairwise)
    maximum = max(x["RMSD_ROTATION_ALIGNED"] for x in pairwise)
else:
    average = None
    minimum = None
    maximum = None

valid = (
    len(runs) >= 2
    and len(normalized) == len(runs)
    and len(pairwise) > 0
    and average is not None
)

result = {
    "RESULT": "PASS" if valid else "FAIL",
    "MODE": "STRUCTURE_NORMALIZATION",
    "INPUT_RUNS": len(runs),
    "NORMALIZED_RUNS": len(normalized),
    "PAIR_COMPARISONS": len(pairwise),
    "ROTATION_ALIGNMENT": True,
    "AVERAGE_RMSD": average,
    "MIN_RMSD": minimum,
    "MAX_RMSD": maximum,
    "ERRORS": errors,
    "PAIRWISE": pairwise
}

OUT.write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
print(f"EVIDENCE={OUT}")

raise SystemExit(0 if valid else 1)
