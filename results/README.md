# Generated Results

Public runners save one experiment artifact and its PDF/PNG figures beneath
this directory. Generated contents are local unless explicitly designated as a
canonical research artifact.

Each active experiment folder contains a short `README.md` stating its research
question, design, headline result, diagnostics, and primary files. Top-level
active folders correspond to supported public outputs. Nested `ep/`,
`original_growth/`, and `zero_growth/` folders are self-contained sub-artifacts
created by their parent runners.

`initialization_robustness/` is the canonical cross-model moderate-prior
comparison. Superseded model-specific initialization outputs and other orphaned
local products were moved to `archive/orphaned_2026-08-03/`; they are not active
evidence and no supported runner writes there.

`results/.gitignore` keeps generated MAT/PDF/PNG/CSV contents local while
explicitly allowing each folder's `README.md` to be versioned with the code.
