# Linear Macro Learning Harness

The harness separates a model experiment into three contracts:

1. A structural model supplies explicitly linear deviation equations, names,
   shocks, calibration, and an independently computed RE solution.
2. An expectations formulation declares the subjective PLM targets, horizons,
   discounts, and mappings used to turn a PLM into decision-relevant forecasts.
3. The learning engine owns RLS updates, gain timing, simulation state, paired
   baseline/shocked paths, diagnostics, and IRFs.

A plug-in is therefore a structural `.mod` file plus an explicit EE or IH
expectations/learning configuration. There is no automatic economic conversion
between EE and IH.

## Dynare 7.1

Set `DYNARE_MATLAB_PATH` to Dynare's `matlab` directory. Alternatively, copy
`structural/local_dynare_config.example.m` to `structural/local_dynare_config.m`
and edit the path. Only Dynare 7.1 is guaranteed. Its version-specific globals,
generated functions, dense dynamic-vector layout, and `horizon=0:Inf` parser
syntax are isolated in `load_dynare_71_linear_model`.

The loader rejects models that are not explicitly declared `model(linear)`.
The E&P benchmark uses a restricted constant-plus-lagged-capital PLM, not a
full VAR. The direct expectation evaluator is used inside learning loops. Dynare's
`var_expectation.initialize` and `var_expectation.update` serve as an independent
reference implementation in tests.

## Models and validations

- `models/ep13_ih_re_linear.mod`: separate 13-variable IH RE representation.
- `models/var_expectation_poc.mod`: one-step and infinite-sum Dynare oracle.
- `tests/models/ep10_euler_re_verification.mod`: verification-only 10-variable
  Euler/RE benchmark; never used by the production learning workflow.

The tests record structural Dynare RE, canonical PLM-to-ALM fixed points, and
legacy E&P solutions separately. Shared-variable comparisons are aligned by
name and timing.

## Run tests

From the impulse-response directory:

```matlab
setup_ir_paths
run_harness_tests
```

Pass `true` to also run the slower 100-draw characterization fixture.
