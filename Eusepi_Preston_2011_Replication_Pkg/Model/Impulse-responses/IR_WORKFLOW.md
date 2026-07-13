# Dynare-Driven Eusepi–Preston IRFs

## Start here

The primary workflow has three explicit inputs and one entrypoint:

- `harness/models/ep13_ih_re_linear.mod` contains the linearized structural
  model and is solved by Dynare 7.1.
- `ep_ih_learning_config()` names the restricted perceived law of motion,
  information set, gain, update timing, forecast targets, and projection rule.
- `make_dynare_ir_config()` supplies Monte Carlo timing, a named shock, draw count,
  seed, and explosion policy.
- `run_dynare_quantities_irfs(...)` runs the experiment and writes the data and
  the single quantities figure.

```matlab
setup_ir_paths
experiment = make_dynare_ir_config();
artifact = run_dynare_quantities_irfs( ...
    fullfile('harness', 'models', 'ep13_ih_re_linear.mod'), ...
    ep_ih_learning_config(), experiment, ...
    fullfile(pwd, 'artifacts', 'dynare_quantities'));
```

The output is `dynare_quantities_results.mat`, `dynare_quantities.pdf`, and
`dynare_quantities.png`. The figure contains consumption, output, investment,
and hours over 40 quarters, with the learning median, RE response, and the
paper's 25th/75th percentile learning band.

## What Dynare does—and what MATLAB does

```text
linear deviation-form .mod
        |
        v
Dynare 7.1: parse equations, solve RE, return equation and decision-rule matrices
        |
        v
named IH adapter: restricted PLM -> E&P subjective present values -> ALM
        |
        v
generic MATLAB RLS loop: train -> paired baseline/shocked paths
        |
        v
completed draws -> quantities -> median / 25th-75th bands -> PDF + PNG
```

Dynare is loaded once per workflow, not once per date or draw. The `.mod` is
the structural driver; MATLAB is the wrapper for subjective forecasts and RLS
belief updates that Dynare's standard RE solution does not perform.

The code does **not** estimate a full VAR. Agents learn seven outcomes using
only a constant and lagged aggregate capital, matching Eusepi–Preston's
restricted PLM. The technology innovation is observed but deliberately absent
from the regressors. Capital-return, wage, and technology-growth forecast sums
are derived from that PLM rather than independently estimated.

## Fidelity boundary

The `.mod` is already written as a linear deviation system. The loader fails
unless it sees `model(linear)`; it never asks Dynare to silently linearize a
nonlinear replacement model. This preserves the paper's sequence: normalize
and log-linearize around the non-stochastic balanced-growth path, then impose
subjective expectations in the infinite-horizon consumption rule.

RE agreement alone is not accepted as evidence of fidelity. An expectation
term can vanish under RE yet matter under learning. Tests therefore compare
the Dynare-driven adapter with the original MATLAB mapping under arbitrary
stable beliefs, and compare complete adaptive-learning paths and quantities
draws at `1e-10`.

One internal normalization is worth making explicit: `rk_sum` and `w_sum` in
the `.mod` store beta times the appendix's discounted sum. The decision
equation compensates by dividing their coefficients by beta. The adapter also
includes expected technology growth, even though its RE forecast is zero for
the benchmark i.i.d. shock.

## Explosions are results

The explosion policy is required data. A magnitude or non-finite trigger stops
the affected path and records the prefix, trigger period, variable, value, and
criterion. Explosive and invalid draws are never replaced by zeros or silently
dropped. The MAT artifact records every status and the figure title reports
completed, explosive, and invalid counts. Plotting fails after saving
diagnostics if no draw completed.

Random-number behavior is unchanged: each replication draws one innovation
vector, then partitions it into training and IR segments. Baseline and shocked
paths restart from identical trained states.

## Code map

```text
run_dynare_quantities_irfs.m     primary public experiment and graph workflow
config/                          explicit experiment, learning, and name schema
harness/structural/              Dynare 7.1 loading and canonical matrices
harness/expectations/            IH subjective forecast / PLM-to-ALM mapping
harness/learning/                generic RLS and paired-path engine
harness/models/                  current .mod and its thin learning compiler
harness/tests/                   fidelity, fail-fast, and workflow tests
harness/tests/models/            verification-only structural fixtures
model/ + generation/             original MATLAB implementation (parity oracle)
legacy_irf/                      isolated historical compatibility renderer
```

The generic harness remains capable of accepting another explicitly linear
`.mod` plus a compatible named configuration. It does not pretend that a new
model automatically has the E&P IH economics: a different expectation
formulation must be supplied explicitly.

`make_ir_config`, `run_benchmark_irfs`, and `run_impulse_responses` remain
temporarily available
for numerical characterization and the older multi-panel artifact. They are
not the primary graph path. The non-regenerable `path_impulses.mat` forecast
panel is not used.

## Verification

```matlab
setup_ir_paths
run_harness_tests(false)  % smoke, structural, arbitrary-belief, path, graph parity
verify_ir_workflow(true, 1e-10)  % include the full historical fixture
```
