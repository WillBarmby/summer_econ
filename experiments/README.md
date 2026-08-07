# Experiments

This directory contains research-owned experiment definitions. Each runnable
experiment folder keeps its Dynare model files, learning specification,
shocks/study options, reporting specification, and README together.

The engine lives under `src/`. It does not contain E&P, NK, or other paper
assumptions. A folder manifest assembles those assumptions into a generic case
definition and delegates execution to the engine.

Current folders:

- `ep_comparison/` contains the paper-direct E&P EE case, the benchmark IH
  case, both model files, and their shared comparison design.
- `nk_technology_ee/` contains the nonlinear NK technology-growth case.
- `archive/old_nk/` contains the unsupported historical NK source only.
