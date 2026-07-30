# Cross-Model Adaptive-Learning Experiments

This repository provides a small research interface for comparing rational
expectations (RE), Euler-equation (EE) learning, and the verified
Eusepi–Preston infinite-horizon (IH) learning specification in RBC and
balanced-growth New Keynesian environments.

The active workflow has six concepts:

1. **Model** - a Dynare file defines the stationary structural economy.
2. **RE solution** - Dynare supplies the rational-expectations benchmark.
3. **Learning specification** - a named configuration states what agents
   forecast, observe, and update.
4. **Training** - agents update beliefs over a recorded sequence of shocks.
5. **Paired IRF** - shocked and unshocked paths restart from the same trained
   state, so their difference isolates the impulse response.
6. **Reporting** - one saved artifact contains the inputs, paths, statuses, and
   graph locations needed to reproduce a result.

## Public commands

From the repository root in MATLAB:

```matlab
setup_project
results = run_ep_comparison();
growth = run_ep_growth_sensitivity();
comparison = run_cross_model_comparison();
risk = run_nk_risk_premium_comparison();
gain = run_nk_gain_sensitivity();
initialization = run_nk_initialization_sensitivity();
ep_initialization = run_ep_initialization_sensitivity();
ep_gain = run_ep_gain_sensitivity();
gain_comparison = run_gain_sensitivity_comparison();
run_fast_tests
run_acceptance_tests
```

The experiment runners are active. With no arguments they use the documented
100-draw defaults and save beneath `results/`; alternatively, pass both a
complete configuration and an output directory. The cross-model runner gives
E&P and NK the same technology-growth innovations and reports both a five-path
overlay and within-model learning-minus-RE panels.

## Project map

- `models/` - verified E&P models, the active nonlinear stationary
  balanced-growth NK model, and one clearly documented historical NK source.
- `config/` - structural calibrations, learning assumptions, and experiment
  settings.
- `src/` - model loading, expectations, learning, simulation, and reporting.
- `tests/` - fast tests, acceptance tests, and compact numerical fixtures.
- `docs/` - equations, experiment design, parameter provenance, and the map to
  the frozen replication history.
- `results/` - generated experiment artifacts and figures.

The full reconstruction is preserved at Git tag `ep-verification-v1`; it is not
part of this branch's active filesystem. The supported runners depend only on
the root-level models, configuration, and source tree. `setup_project` also
removes stale frozen-tree entries left by an earlier MATLAB session so legacy
functions cannot silently shadow the clean interface. See
[`docs/REPLICATION_LINEAGE.md`](docs/REPLICATION_LINEAGE.md) for the archived
equivalence evidence and the fixture-based regression checks that carry it
forward.

See [Documentation map](docs/README.md) for the intended reading order.
