# Changelog

## 0.1.0-research-preview

This release establishes the packaging branch as the active face of the
adaptive-learning engine.

- Added relocatable folder-local experiments with one `experiment.m` manifest
  and the `run_experiment_folder` convenience entry point.
- Unified paired baseline/shocked execution and schema-3 study artifact
  construction.
- Kept structural extraction on Dynare's analytical `dynamic_g1` Jacobian for
  both linear and nonlinear models.
- Kept rational-expectations solution extraction at the separate Dynare
  decision-rule boundary.
- Removed obsolete pre-packaging learning helpers.
- Added schema-3 artifact validation, persistence, reporting, and reusable
  training/IRF workflows to the documented active contract.
- Added a tiny self-contained experiment and documented the historical
  experiment/figure migration backlog.
- Moved the retained E&P and NK definitions and active Dynare sources into
  self-contained experiment folders; comparison manifests now support multiple
  local cases.

Historical paper runners are intentionally not all migrated in this release.
See `ROADMAP.md` for the remaining work.
