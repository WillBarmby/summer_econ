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
   graph locations needed to reproduce a result. Every runner also writes a
   compact CSV of paper-facing metrics.

## Public commands

From the repository root in MATLAB:

```matlab
setup_project
results = run_ep_comparison();
growth = run_ep_growth_sensitivity();
comparison = run_cross_model_comparison();
risk = run_nk_risk_premium_comparison();
technology = run_nk_technology_comparison();
gain = run_nk_gain_sensitivity();
initialization_comparison = run_initialization_robustness();
ee_consumption = run_ep_ee_consumption_audit();
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

## Headline findings

- E&P IH generates substantially larger technology-shock amplification than
  either E&P one-step EE or NK one-step EE at the benchmark gain.
- Learning wedges rise with the gain. E&P IH is the most gain-sensitive and
  has 53 explosive draws at gain `0.02`, so that cell's median is conditional
  on 47 completions.
- Directly learning consumption forecasts changes the relatively small E&P EE
  response, especially investment.
- Positive deterministic growth affects response magnitudes but does not
  explain the EE-IH ranking.
- After 2,000 training observations, IH is comparatively insensitive to a
  half-RE starting prior; E&P EE and NK EE retain meaningful prior dependence.

Each runner's research question, result metric, numerical summary, and claim
boundary are collected in
[`docs/RESULTS_AND_QUESTIONS.md`](docs/RESULTS_AND_QUESTIONS.md).

## Project map

- `models/` - verified E&P models, the active nonlinear stationary
  balanced-growth NK model, and one clearly documented historical NK source.
- `config/` - structural calibrations, learning assumptions, and experiment
  settings.
- `src/` - model loading, expectations, learning, simulation, and reporting.
- `experiments/` - harmonized paper-facing orchestration and figures.
- `tests/` - fast tests, acceptance tests, and compact numerical fixtures.
- `docs/` - equations, experiment design, parameter provenance, and the map to
  the frozen replication history.
- `results/` - generated experiment artifacts and figures.

The standalone NK technology-shock runner reports the four real quantities
plus inflation and the nominal rate. Its six-panel figure complements the
four-quantity cross-model technology-shock comparison, where nominal
quantities cannot be shared with the E&P model.

The full reconstruction is preserved at Git tag `ep-verification-v1`; it is not
part of this branch's active filesystem. The supported runners depend only on
the root-level models, configuration, and source tree. `setup_project` also
removes stale frozen-tree entries left by an earlier MATLAB session so legacy
functions cannot silently shadow the clean interface. See
[`docs/REPLICATION_LINEAGE.md`](docs/REPLICATION_LINEAGE.md) for the archived
equivalence evidence and the fixture-based regression checks that carry it
forward.

See [Documentation map](docs/README.md) for the intended reading order.
The MAT/CSV field contract is documented in
[`docs/ARTIFACT_SCHEMA.md`](docs/ARTIFACT_SCHEMA.md).
