# E&P Learning Experiments

This repository is being reorganized around a small research interface for
comparing rational expectations (RE), Euler-equation (EE) learning, and the
verified Eusepi-Preston infinite-horizon (IH) learning specification.

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
run_fast_tests
run_acceptance_tests
```

The E&P experiment runners are active. With no arguments they use the documented
100-draw defaults and save beneath `results/`; alternatively, pass both a
complete configuration and an output directory. The public test-suite wrappers
will be activated in Phase 4.

## Project map

- `models/` - active Dynare models; the balanced-growth NK model will be added
  only after its stationary equations have been derived and reviewed.
- `config/` - structural calibrations, learning assumptions, and experiment
  settings.
- `src/` - model loading, expectations, learning, simulation, and reporting.
- `tests/` - fast tests, acceptance tests, and compact numerical fixtures.
- `docs/` - equations, experiment design, parameter provenance, and the map to
  the frozen replication history.
- `results/` - generated experiment artifacts and figures.

The existing `Eusepi_Preston_2011_Replication_Pkg/` tree remains the frozen,
runnable verification implementation during this transition. The active E&P
runners use only the new root-level models, configuration, and source tree.
`setup_project` removes frozen-tree entries left by an earlier MATLAB session
before adding the supported clean paths. See Git tag `ep-verification-v1` and
[`docs/REPLICATION_LINEAGE.md`](docs/REPLICATION_LINEAGE.md) for the archived
equivalence evidence.

See [Documentation map](docs/README.md) for the intended reading order.
