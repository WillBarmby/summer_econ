# Adaptive-Learning Research Engine

This branch is the small active core for building generalized model-based
experiments. Dynare remains behind the model loader; the learning engine works
with explicit MATLAB contracts rather than knowing about a particular paper or
economic model.

The intended handoffs are:

1. a model file is solved and converted into a canonical structural model;
2. Dynare's first-order RE decision rule becomes the initial RE law;
3. a learning specification defines the PLM, beliefs, regressors, and updater;
4. the experiment engine repeatedly maps beliefs to an ALM and simulates paths;
5. the experiment returns paths, belief states, diagnostics, and artifacts.

The active code contains the complete linear-model pipeline, one-step and
infinite-horizon expectation mappings, one-draw and comparison runners, and
nonexecutable artifact/reporting consumers.

## Install and verify

The active workflow requires MATLAB R2026a and Dynare 7.1. The model boundary
expects Dynare's MATLAB path at `/Applications/Dynare/7.1-arm64/matlab` on the
reference macOS setup, or the equivalent path in the `DYNARE_MATLAB_PATH`
environment variable. `setup_project` configures the repository paths and
checks the Dynare boundary when a model is loaded.

From the repository root in MATLAB, run:

```matlab
setup_project;
run_core_tests;
run_acceptance_tests;
```

From another working directory, add the checkout root once before calling the
same setup function:

```matlab
addpath("/absolute/path/to/packaging");
setup_project;
```

The core suite exercises the contracts and engine. The acceptance suite runs
the retained E&P and NK numerical parity checks. The reference environment is
recorded in `tests/fixtures/README.md`; other MATLAB/Dynare versions should be
treated as unverified until the suites pass there.

## Current release scope

This is a research-preview engine, not a migration-complete release of every
historical paper runner. The stable interface is the explicit model, RE,
learning, experiment, study, and schema-3 artifact handoff described in
`ARCHITECTURE.md`. Version 1 supports RLS learning, constant and lagged-variable
regressor descriptors, the current gain schedules, declarative coefficient
scaling, and the retained E&P/NK demonstrations. Historical experiments and
their paper figures are tracked as migration work in `ROADMAP.md`.

The folder-local runner is intended to be the normal starting point for a new
experiment. Lower-level functions remain available when a researcher needs to
reuse a prepared case or training artifact.

The public lower-level workflow separates model preparation, training, and IRF
evaluation. A research experiment normally supplies the definition from its
local manifest:

```matlab
setup_project;
definition = ... % supplied by the local experiment manifest
ee = prepare_case(definition); % Dynare runs here
study = learning_irf_design(learning_irf_options());

training = train_case(ee,study.training);
irf = run_irf(ee,training,study.irf);
result = run_case(ee,study); % equivalent convenience wrapper
```

The prepared case may be reused without rerunning Dynare, and the training
artifact may be reused for several IRF designs without retraining. The retained
E&P comparison is packaged with both cases and its comparison-level manifest:

```text
experiments/ep_comparison/
    ep_rbc_ee.mod
    ep_rbc_ih.mod
    experiment.m
    README.md
```

Run it with:

```matlab
comparison = run_experiment_folder( ...
    "/absolute/path/to/packaging/experiments/ep_comparison");
```

Several learning cases for one model can also reuse a loaded model and RE law:

```matlab
model = load_model(model_file,model_options);
re = solve_re(model);
case_a = prepare_case(definition_a,model,re);
case_b = prepare_case(definition_b,model,re);
```

The nonlinear NK technology case uses the same public preparation and study
boundary from its own folder:

```matlab
nk_artifact = run_experiment_folder( ...
    "/absolute/path/to/packaging/experiments/nk_technology_ee");
```

New experiments can be self-contained folders. A single-case folder's
`experiment.m` manifest returns `case_definition` and `study_options`; a
comparison folder returns `case_definitions` and `study_options`. Both keep
their Dynare model files locally:

```matlab
setup_project;
artifact = run_experiment_folder("examples/tiny_linear_experiment");
```

The manifest resolves its model path relative to its own folder, so adding a
new model does not require editing the root case or study files. See
`examples/tiny_linear_experiment/` for the complete convention.

Artifacts are inert schema-3 data. Saving validates them and writes a canonical
MAT file plus a readable JSON metadata sidecar:

```matlab
paths = save_artifact("results/example.mat",result);
restored = load_artifact(paths.mat);
```

## Project map

- `experiments/` - research-owned model files, manifests, and study designs.
- `src/model/` - Dynare integration, stationary transformations, structural
  matrices, and RE-law extraction.
- `src/expectations/` - expectation mappings from a PLM to an ALM.
- `src/learning/` - declarative learning validation and the callback-based
  learning compiler.
- `src/case/` - generic case preparation from a definition to compiled runtime
  values; concrete research cases live under `experiments/`.
- `src/study/` - named-shock designs and single/comparison execution.
- `src/artifact/` - nonexecutable schemas, validation, description, and safe
  MAT/JSON persistence.
- `src/reporting/` - pure summaries and in-memory graph consumers.
- `tests/` - focused loader and engine tests.
- `docs/` - historical research and experiment documentation retained for
  provenance; it does not describe every active file in this branch.

Call `setup_project` from MATLAB before using the active functions. Historical
paper-specific code remains in Git under `experiments/`; the engine does not
contain paper-specific runners or assumptions.
