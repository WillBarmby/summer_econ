# Harmonized Initialization Robustness

`run_initialization_robustness` is the paper-facing comparison of exact RE and
half-RE forecasting coefficients in E&P EE, E&P IH, and NK EE. It fixes the
standard gain and training period, generates every innovation history once,
and applies one draw-first statistic across all specifications.

From the repository root in MATLAB:

```matlab
setup_project
result = run_initialization_robustness();
```

The runner writes one MAT artifact, a flat CSV summary, treatment IRFs, direct
paired-difference panels, and a scalar robustness summary beneath
`results/initialization_robustness/`. Existing model-specific runners remain
available for multiple training horizons and zero-coefficient stress tests.
