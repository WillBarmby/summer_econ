# Impulse-Response Workflow

This folder generates impulse responses for the Eusepi-Preston model. The
current code is a light refactor of legacy MATLAB scripts, so the main goal of
the structure is to preserve existing numerical behavior while making the
execution path easier to follow.

## Entrypoints

- `Main_imp_resp_Sept_2009.m` is the legacy-compatible entrypoint. It loads the
  default configuration, applies optional workspace overrides, and calls
  `run_impulse_responses`.
- `run_imp_resp_artifacts.m` runs the generator twice: once with learning on and
  once under rational expectations. It saves the two raw IR cell arrays used by
  the benchmark plots.
- `run_ir_baseline_artifacts.m` and `verify_ir_baseline.m` are characterization
  harnesses. They are used to confirm that refactors did not change the current
  numerical output.

## High-Level Flow

1. `make_ir_config` explicitly constructs the reference horizon, training length, model parameters,
   shock scale, learning flag, and output defaults.
2. `run_impulse_responses` draws random shock histories and loops over Monte
   Carlo draws.
3. `simulate_ir_draw` computes one draw by comparing an unshocked path with a
   path that receives one additional normalized shock.
4. `simulate_model_paths` runs the model engine. With learning on, beliefs are
   updated recursively. With learning off, the rational-expectations solution is
   used directly.
5. `build_ir_series` converts raw model rows and expectation arrays into the 14
   reported impulse-response series.
6. `summarize_ir_bands` computes medians and order-statistic bands across draws.

`run_impulse_responses` requires a complete configuration and validates it
before simulation. A configured magnitude or non-finite trigger terminates the
affected draw and returns the observed path prefix and trigger metadata. Such a
draw is reported as explosive rather than silently converted to zeros.

## Baseline Path vs Shocked Path

Each draw uses the same random history for the baseline and shocked simulations.
The baseline simulation first runs through the training sample and saves the
model's internal state at the end of that training period. The shocked
simulation restarts from that saved state and adds one extra shock at the first
impulse-response period.

The impulse response is:

```text
shocked reported series - baseline reported series
```

This keeps the pre-shock history, model state, and learning state identical
across the two paths.

## Timing Convention

The saved training state corresponds to period `sim_L + 1`. The additional
impulse-response shock affects the transition into period `sim_L + 2`, so the
first reported response is the impact response at `sim_L + 2`.

For growth variables, the first reported growth response is computed as the
period `sim_L + 2` value less the period `sim_L + 1` value. The reported IR has
length `T_imp - 1`.

## Learning vs Rational Expectations

The `learning` flag controls the law of motion used inside `simulate_model_paths`.

- `learning = true`: the perceived law of motion is updated during simulation
  using recursive least squares. Beliefs feed back into the next simulated
  period when `feedback = true`.
- `learning = false`: the fixed rational-expectations law of motion is used, and
  beliefs are not updated.

`run_imp_resp_artifacts.m` uses this switch to save both learning and rational
expectations impulse responses.

## Reported IR Series

The 14 reported rows are defined by `ir_variable_indices` and constructed in
`build_ir_series`:

1. wage, detrended cumulative response
2. consumption, detrended cumulative response
3. investment, detrended cumulative response
4. output, detrended cumulative response
5. bond/riskless return, direct level response
6. hours, direct level response
7. return to capital, direct level response
8. wage level, direct level response
9. expected return to capital, short horizon
10. expected wage, short horizon
11. expected return to capital, longer horizon
12. expected return to capital, longer horizon
13. expected wage, longer horizon
14. expected wage, longer horizon

The first four series are cumulative because the raw model output is converted
from growth responses into detrended level responses. The remaining series are
taken directly from raw model rows or expectation arrays.
