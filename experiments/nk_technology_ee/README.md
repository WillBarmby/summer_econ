# NK technology-growth learning experiment

This folder contains the nonlinear stationary NK model, its learning and
reporting specifications, and the study options in one local manifest.

Run it after initializing the engine:

```matlab
addpath("/absolute/path/to/packaging");
setup_project;
artifact = run_experiment_folder( ...
    "/absolute/path/to/packaging/experiments/nk_technology_ee");
```

The result is a schema-3 `training_irf` artifact. Structural matrices come
from Dynare's analytical `dynamic_g1`; the separate RE handoff uses Dynare's
first-order decision rule.
