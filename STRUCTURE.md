# Protein Structure

## Canonical source

- `protein/00-core` — core maps and system structure
- `protein/11-molecules` — beads and molecule processing
- `protein/12-runtime/development/candidates` — active development processors
- `protein/12-runtime/state` — runtime state retained by the protein source

## Processing groups

### BEAD
- bead20.py
- bead20-mutation-unit.py
- bead20-mutation-pair.py
- bead20-co-mutation.py

### CONTRACT
- bead20-motion.py
- bead20-collision-contract.py
- bead20-collision-contract-v2.py
- bead20-constraint-stress.py

### FOLDING
- bead20-self-fold.py
- bead20-self-fold-v2.py
- bead20-self-fold-multiseed.py
- bead20-self-fold-compare.py

### RELATION
- bead20-propagation-selection.py
- bead20-relation-conservation.py
- bead20-normalization.py
- bead20-convergence-v2.py

### MOLECULE
- molecule-bead.zsh
- molecule-engine.zsh

## Execution

`containers/protein/bin/process.zsh` is the human-facing processor entrypoint.

`containers/protein/bin/processing-worker.zsh` is the isolated processing worker.

## Evidence and output

Development evidence remains under:

`protein/12-runtime/development/evidence`

Execution output remains under:

`runtime/protein`

Historical/legacy material is retained until dependency references are audited.

## Safety

Canonical source must remain read-only during isolated processing.

No AWS mutation.

No root mutation.

No historical destructive engine execution.
