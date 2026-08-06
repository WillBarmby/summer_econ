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

The verified E&P comparison is intentionally short to invoke:

```matlab
setup_project;
options = ep_comparison_options();
ee = prepare_case(ep_ee_case(options));
ih = prepare_case(ep_ih_case(options));
comparison = run_comparison({ee,ih},ep_comparison_design(options));
```

For a single explicit draw, select one row from the design's standardized
innovations and call `run_case`. That artifact retains full training and IRF
histories; `run_comparison` retains compact draw evidence and summaries.

The nonlinear NK technology case uses the same public preparation and study
boundary:

```matlab
nk = prepare_case(nk_ee_case(options));
nk_artifact = run_case(nk,one_draw_design);
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
- `src/artifact/` - nonexecutable schemas, validation, and description.
- `src/reporting/` - pure summaries and in-memory graph consumers.
- `tests/` - focused loader and engine tests.
- `docs/` - historical research and experiment documentation retained for
  provenance; it does not describe every active file in this branch.

Call `setup_project` from MATLAB before using the active functions. Historical
paper-specific code remains in Git; the new E&P case layer reproduces its
verified baseline without reintroducing the old bundled runner boundaries.
