# Generic case preparation

This directory contains only the engine-side case boundary. `prepare_case`
accepts a case definition assembled by a local experiment manifest, loads or
reuses the structural model and RE solution, compiles the declarative learning
specification, and returns runtime handoff values.

Paper-specific case factories, model files, calibration choices, learning
assumptions, and reporting specifications belong under `experiments/`, not in
this directory.
