# Balanced-Growth NK Model Development

> **Historical documentation.** This records the former model-development
> workflow and its experiment context. The active branch retains the Dynare
> model-loader code and model files while rebuilding the surrounding contracts.

## Implemented design

The active `experiments/nk_technology_ee/nk_balanced_growth.mod` uses
labor-augmenting technology and
stationary variables normalized by the stochastic technology level, matching
the aspects of the E&P growth environment required for the comparison. The
earlier technology-level specification is retained as
`experiments/archive/old_nk/old_nk.mod` only
to make the rewrite auditable; supported runners never load it.

The rewrite was developed in reviewable stages:

- define the technology level and gross technology growth;
- specify the timing of consumption, output, investment, capital, and wages in
  efficiency units;
- derive normalized equilibrium conditions and the balanced-growth steady
  state; and
- state agents' information and forecasting assumptions independently of the
  structural equations.

The production Dynare file contains the nonlinear stationary model. Dynare
computes its analytical first-order approximation, and MATLAB performs a small,
explicit conversion from additive deviations to proportional percentage units.
A separate hand-linearized NK production model is deliberately not maintained.

The source derivation is `docs/model_simple_dynare.tex`. Loader and model tests
check the steady state, analytical Jacobian, RE law, shock units, capital timing,
and parameter overrides. Future structural changes should preserve the same
sequence: derive and review the stationary economics first, transcribe it into
Dynare second, and add learning assumptions separately in MATLAB.
