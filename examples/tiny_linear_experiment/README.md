# Tiny linear experiment

This folder is a complete local experiment definition. The model, learning
specification, reporting specification, and study options live beside the
Dynare file and do not require edits to the root case files.

From the repository root in MATLAB:

```matlab
setup_project;
artifact = run_experiment_folder( ...
    fullfile(pwd,"examples","tiny_linear_experiment"));
```

The returned value is the standard schema-3 `training_irf` artifact.
