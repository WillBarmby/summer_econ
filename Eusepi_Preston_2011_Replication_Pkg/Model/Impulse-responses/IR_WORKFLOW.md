# Impulse-Response Workflow

## Start here

The public workflow has four concepts:

1. `make_ir_config()` constructs the explicit reference experiment.
2. `run_impulse_responses(config)` runs one learning or RE experiment.
3. `run_benchmark_irfs(config, plot_spec, output_dir)` runs both cases and
   writes the benchmark data plus PDF and PNG figures.
4. `verify_ir_workflow(include_full_fixture, tolerance)` runs structural,
   characterization, graph-workflow, and legacy-parity checks.

Generate the 100-draw benchmark from this directory:

```matlab
setup_ir_paths
config = make_ir_config();
config.main.n_draws = 100;
config.main.store_output = false;
spec = benchmark_plot_spec(0, 0);
artifact = run_benchmark_irfs(config, spec, fullfile(pwd, 'artifacts', 'benchmark_irfs'));
```

The output directory contains `benchmark_irf_results.mat` and four figures in
both PDF and PNG format: quantities, expected sums, forecast errors, and the
long-horizon return forecast.

## Data flow

```text
make_ir_config
      |
      v
run_benchmark_irfs
      |
      +--> run_impulse_responses (learning)
      |         `--> simulate_ir_draw --> simulate_model_paths
      |
      +--> run_impulse_responses (rational expectations)
      |         `--> simulate_ir_draw --> simulate_model_paths
      |
      `--> completed draws --> medians / 15th-85th bands --> PDF + PNG
```

Each IR draw trains the model once, restarts the same saved state for baseline
and shocked paths, and reports `shocked - baseline`. The first reported period
is the impact response at training period `sim_L + 2`.

## Explosions and invalid runs

The explicit explosion policy is part of the configuration. A magnitude or
non-finite trigger stops the affected path and preserves its prefix, trigger
period, variable, value, and criterion. It is never converted to a zero IRF.

Graphs use completed draws only. Every saved artifact records completed,
explosive, and invalid counts. Graph generation fails if either learning or RE
has no completed draws.

## Directory map

```text
config/                 explicit reference configuration and variable schema
generation/             Monte Carlo IR engine and reported-series mapping
model/                  Eusepi-Preston matrices and path simulator
Plot_imp_resp_Bench/    explicit plot specification and parity renderer
harness/                general Dynare/learning research harness and tests
legacy_irf/              isolated compatibility adapter
notes/                   inactive historical equation alternatives
*.mat                    checked characterization fixtures
```

Production code does not call the legacy adapter. Only verification uses it.
The historical `path_impulses.mat` file is not used because the code that
generated it is absent; consequently the old forecast-path panel is omitted.

## Reported series

`ir_variable_indices` names the model positions. `build_ir_series` maps paths
to fourteen reported IRs: four cumulative quantity responses, four direct
asset/labor responses, and six subjective forecast responses. The benchmark
workflow additionally carries discounted capital- and labor-income sums in
draw metadata for the expected-sums figure without changing the characterized
fourteen-series output contract.
