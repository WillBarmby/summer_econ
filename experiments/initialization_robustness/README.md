# Harmonized Initialization Robustness

`run_initialization_robustness` is the paper-facing comparison of exact RE and
half-RE forecasting coefficients in E&P EE, E&P IH, and NK EE. It fixes the
standard gain, nests training periods of 0, 100, 500, and 2,000 observations
within each innovation history, and applies one draw-first statistic throughout.

From the repository root in MATLAB:

```matlab
setup_project
result = run_initialization_robustness();
```

The runner writes one MAT artifact, a flat CSV summary, 2,000-period treatment
and paired-difference panels, a scalar robustness summary, and an appendix
training-horizon figure beneath
`results/initialization_robustness/`. It supersedes the former model-specific
initialization runners with one shared workflow across all three specifications.
