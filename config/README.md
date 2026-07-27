# Configuration

Configuration is separated by purpose:

- `ep_calibration` records structural parameter overrides.
- `ep_experiment_config` records simulation and reporting choices.
- `ep_ee_specification` states what one-step EE agents estimate and observe.
- `ep_ih_specification` states the verified infinite-horizon information set.
- `nk_ee_specification` states which NK forecasts agents estimate under the
  one-step EE comparison and keeps those assumptions outside the Dynare model.
- `nk_risk_premium_ee_specification` records the corresponding information
  assumption for the i.i.d. NK risk-premium experiment.

The first cross-model runner deliberately reuses `ep_experiment_config`, so the
models share the draw count, seed, training length, gain, horizon, technology
shock volatility, and impulse. NK-specific learning assumptions remain in
`nk_ee_specification`.

No experiment requires editing a Dynare model file in multiple places.
