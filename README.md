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

The active code currently contains the model loaders, structural validation,
one-step PLM-to-ALM mapping, RLS updater, and recursive simulation primitives.
The generic specification compiler and experiment artifact layer are the next
pieces to build.

## Project map

- `models/` - Dynare model files used as concrete loader examples.
- `src/model/` - Dynare integration, stationary transformations, structural
  matrices, and RE-law extraction.
- `src/expectations/` - expectation mappings from a PLM to an ALM.
- `src/learning/` - belief state, RLS updates, recursive simulation, and paired
  path primitives.
- `tests/` - focused loader and engine tests.
- `docs/` - historical research and experiment documentation retained for
  provenance; it does not describe every active file in this branch.

Call `setup_project` from MATLAB before using the active functions. The former
paper-specific runners, reporting code, and experiment configurations have
been removed from the active tree. Their research history remains in Git and
in the historical documentation under `docs/`.
