# Protein Architecture Contract

## Purpose

Protein is developed locally first.
External systems such as AWS are optional accelerators, not dependencies.

## Canonical Structure

protein/
├── 00-core/
├── 07-quarantine/
│   └── development/
└── 12-runtime/
    ├── development/
    │   ├── candidates/
    │   ├── evidence/
    │   └── ARCHITECTURE.md
    └── state/
        ├── rollback/
        └── audit-evidence/

## Roles

00-core
Confirmed and protected system.
Candidate code must not modify Core directly.

12-runtime/development/candidates
Only place for new development candidates.

12-runtime/development/evidence
Evidence produced by candidate checks and tests.

07-quarantine/development
Failed or unsafe candidates.
Keep for inspection and fold-back.
Do not delete automatically.

12-runtime/state/rollback
Recovery and rollback checkpoints.

12-runtime/state/audit-evidence
System-level audit evidence.

## Development Flow

CANDIDATE
    ↓
CHECK
    ↓
TEST
    ↓
EVIDENCE
    ↓
VERIFY
    ↓
PASS → REVIEW → CORE
FAIL → QUARANTINE → ROLLBACK

## Safety Rules

CORE_MUTATION=NO
CORE_DELETE=NO
CORE_MOVE=NO
AWS_MUTATION=NO
BACKGROUND_START=NO
AUTO_PROMOTION=NO
AUTO_DELETE=NO

## Command Gate

Important execution must pass through the Nib command gate.

Nib policy:

CHECK
→ OBSERVE
→ POLICY
→ DISCOVER
→ MEASURE
→ EVIDENCE
→ VERIFY
→ PROMOTE or FOLD-BACK

## Evidence Rule

Every meaningful experiment must leave evidence containing:

TIMESTAMP
TARGET
INPUT
OUTPUT
COST
LIMIT
RESULT
CHECKSUM

## Recovery Rule

Known-good state must remain recoverable.

No experiment may consume the last recovery path.

## Simplification Rule

Do not create another directory, gate, engine, manifest, benchmark,
or policy when an existing component already provides the same role.

One role = one canonical location.

## Current Development Entry Point

Candidate test:

~/.config/dynu-audit/protein-candidate-test.sh

Candidate location:

protein/12-runtime/development/candidates/

## Current Status

ARCHITECTURE=CANONICAL
MODEL=CANDIDATE_CHECK_TEST_EVIDENCE_KEEP_OR_FOLD_BACK
CORE_PROTECTED=YES
AWS_DEPENDENCY=NO
AUTO_PROMOTION=NO
AUTO_DELETE=NO
ROLLBACK=REQUIRED

## Development Policy

### Development Principle

Development is open and flexible.
Safety limits impact, not experimentation.

### Allowed Development

Candidates may:

- explore new algorithms
- create alternative implementations
- compare multiple approaches
- benchmark resource usage
- use external compute when useful
- connect to optional external systems
- fail and be retained for analysis
- evolve into improved candidates

### Protected Assets

The following must remain recoverable:

- 00-core
- original evidence
- recovery path
- verified state
- source data

### Isolation Rule

Development work remains outside Core until verified.

Candidate changes must not directly overwrite Core.

### Resource Rule

Resource limits are experiment inputs.

When local resources are insufficient, computation may move to an external accelerator.

External computation must return:

RESULT
EVIDENCE
CHECKSUM
LIMITS

External systems are optional accelerators, not Core dependencies.

### Failure Rule

Failure is preserved as knowledge.

FAIL
→ QUARANTINE
→ ANALYZE
→ IMPROVE
→ NEW CANDIDATE

No automatic deletion of failed development artifacts.

### Promotion Rule

PASS does not automatically modify Core.

PASS
→ REVIEW
→ PROMOTE

Promotion must remain reversible.

### Expansion Rule

New capability may be added without redesigning the Root.

Prefer extending existing canonical components over creating duplicate systems.

### Simplification Rule

ONE ROLE = ONE CANONICAL LOCATION

Do not create a new gate, engine, manifest, directory, or policy when an existing component already provides the same role.

### Architecture Invariant

DEVELOPMENT MAY EXPAND
CORE MUST REMAIN RECOVERABLE
FAILURE MUST BE REVERSIBLE
EVIDENCE MUST SURVIVE
EXTERNAL SYSTEMS MUST REMAIN OPTIONAL

### Development Model

OPEN_DEVELOPMENT
→ ISOLATE
→ CHECK
→ TEST
→ MEASURE
→ EVIDENCE
→ VERIFY
→ KEEP_OR_FOLD_BACK
→ REVIEW
→ PROMOTE

