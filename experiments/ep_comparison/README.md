# E&P EE/IH comparison

This is the retained Eusepi–Preston comparison. The folder contains both
Dynare model files and the complete comparison manifest:

- the paper-direct one-step Euler-equation case (`ep_ee`);
- the infinite-horizon benchmark case (`ep_ih`);
- their learning specifications and reporting choices;
- the shared training/IRF study design.

Run it after initializing the engine:

```matlab
addpath("/absolute/path/to/packaging");
setup_project;
comparison = run_experiment_folder( ...
    "/absolute/path/to/packaging/experiments/ep_comparison");
```

The returned value is a schema-3 `comparison` artifact. The two cases are
paired on identical standardized innovations and remain independently
inspectable in `comparison.cases{1}` and `comparison.cases{2}`.

The optional argument to `experiment` exists for parity tests and controlled
research variation; normal use should run the default manifest.
