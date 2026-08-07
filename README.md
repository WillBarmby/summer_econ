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

The public workflow separates model preparation, training, and IRF evaluation:

```matlab
setup_project;
case_options = ep_case_options();
study_options = learning_irf_options();

ee = prepare_case(ep_ee_case(case_options)); % Dynare runs here
study = learning_irf_design(study_options);

training = train_case(ee,study.training);
irf = run_irf(ee,training,study.irf);
result = run_case(ee,study); % equivalent convenience wrapper
```

The prepared case may be reused without rerunning Dynare, and the training
artifact may be reused for several IRF designs without retraining. To compare
models under identical innovations:

```matlab
ih = prepare_case(ep_ih_case(case_options));
comparison = run_comparison({ee,ih},study);
```

Several learning cases for one model can also reuse a loaded model and RE law:

```matlab
model = load_model(model_file,model_options);
re = solve_re(model);
case_a = prepare_case(definition_a,model,re);
case_b = prepare_case(definition_b,model,re);
```

The nonlinear NK technology case uses the same public preparation and study
boundary:

```matlab
nk = prepare_case(nk_ee_case(nk_case_options()));
nk_artifact = run_case(nk,study);
```

Artifacts are inert schema-3 data. Saving validates them and writes a canonical
MAT file plus a readable JSON metadata sidecar:

```matlab
paths = save_artifact("results/example.mat",result);
restored = load_artifact(paths.mat);
```

## Project map

- `models/` - Dynare model files used as concrete loader examples.
- `src/model/` - Dynare integration, stationary transformations, structural
  matrices, and RE-law extraction.
- `src/expectations/` - expectation mappings from a PLM to an ALM.
- `src/learning/` - belief state, RLS updates, recursive simulation, and paired
  path primitives.
- `src/case/` - readable model-specific case definitions and preparation.
- `src/study/` - named-shock designs and single/comparison execution.
- `src/artifact/` - nonexecutable schemas, validation, description, and safe
  MAT/JSON persistence.
- `src/reporting/` - pure summaries and in-memory graph consumers.
- `tests/` - focused loader and engine tests.
- `docs/` - historical research and experiment documentation retained for
  provenance; it does not describe every active file in this branch.

Call `setup_project` from MATLAB before using the active functions. Historical
paper-specific code remains in Git; the new E&P case layer reproduces its
verified baseline without reintroducing the old bundled runner boundaries.
