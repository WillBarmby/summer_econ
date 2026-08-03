# Harmonized Initialization Robustness

**Research question:** how much do learning IRFs depend on exact-RE rather than
half-RE starting coefficients, and how quickly does training remove that
dependence?

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

## Result

All 100 draws complete in every treatment and horizon, with no projection
events. After 2,000 observations, the median fraction of the initial coefficient
displacement retained is 48.8 percent for E&P EE, 17.7 percent for E&P IH, and
27.4 percent for NK EE. Relative to each specification's RE-initialized learning
wedge, the remaining initialization effect is roughly 17 times as large for
E&P EE and 18-24 times as large for NK EE, but only about 5 percent as large for
E&P IH.

The exercise compares two moderate priors. It is not a zero-prior stress test or
a map of global convergence.
