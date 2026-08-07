# Tiny linear experiment

This folder is a complete local experiment definition. The model, learning
specification, reporting specification, and study options live beside the
Dynare file and do not require edits to the root case files.

From any working directory in MATLAB, after adding the checkout root to the
MATLAB path:

```matlab
addpath("/absolute/path/to/packaging");
setup_project;
artifact = run_experiment_folder( ...
    "/absolute/path/to/packaging/examples/tiny_linear_experiment");
```

The returned value is the standard schema-3 `training_irf` artifact. For a
checkout at the repository root, the equivalent call is:

```matlab
artifact = run_experiment_folder( ...
    fullfile(pwd,"examples","tiny_linear_experiment"));
```

The example should finish with:

```matlab
artifact.kind      % "training_irf"
artifact.status    % "completed"
artifact.case.id   % "tiny_linear"
```

It runs one short training draw followed by a five-period impulse-response
evaluation. It requires MATLAB and Dynare 7.1, but does not require editing
any root-level case or study file. The folder can be copied elsewhere as long
as its `.mod` file remains beside `experiment.m`.
