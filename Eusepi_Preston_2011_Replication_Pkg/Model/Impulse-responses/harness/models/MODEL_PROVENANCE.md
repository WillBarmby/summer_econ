# Model provenance and calibration policy

The model files preserve their source calibrations. Experiments apply named
parameter overrides through configuration and store both the source and
effective calibration. Do not edit a `.mod` calibration merely to run a new
experiment.

## Eusepi–Preston model

- Economic source: Eusepi and Preston (2011), replication package.
- Harness source: `ep13_ih_re_linear.mod` for the infinite-horizon RE
  representation and `ep_ee_paper.mod` for paper-style Euler-equation learning.
- Coordinates: log/proportional deviations from the balanced-growth path.
- Technology: investment-neutral technology-growth deviation `gamma_x`, with
  innovation `eps_x` and source persistence `rho_x = 0`.
- Information: the current technology innovation is observed and affects
  decisions, but is excluded from the capital-only forecasting regression.

## Rotemberg New Keynesian model with capital

- Economic source: `NK_Models/model/model_simple.tex`, Model 2 ("Baseline with
  Capital"), from the advisor project.
- Harness source: `nk_nonlinear_rotemberg_pricing.mod`.
- Source coordinates: stationary nonlinear levels. The harness extracts the
  first-order system and converts positive variables to log deviations.
- Technology: technology-level deviation `technology`, with innovation
  `eps_technology` and source persistence `rho_technology = 0.9`.
- Deliberate specializations: unconstrained Taylor rule (no ZLB), steady-state
  output target, constant discount factor, and no capital adjustment costs or
  Tobin's q. See the `.mod` header for details.
- Machine-readable source values and named overrides:
  `config/nk_model_calibration_config.m`.

## Shared-parameter crosswalk

| Economic object | E&P name/value | NK name/source value |
|---|---|---|
| Discount factor | `beta`, with growth-adjusted `beta_tilda` | `beta = 0.995` |
| Depreciation | `delta = 0.025` | `delta = 0.025` |
| Capital share | `alpha = 0.34` | `alpha = 0.33` |
| Technology persistence | `rho_x = 0` | `rho_technology = 0.9` |
| Technology innovation | growth innovation `eps_x` | level innovation `eps_technology` |

Equal names do not by themselves imply equal economic definitions. In
particular, the technology shocks remain growth and level shocks respectively.

## Initial common comparison

The `iid_comparison` NK calibration overrides `rho_technology` to zero. The E&P
benchmark already has `rho_x = 0`. Both sets of agents therefore observe the
current i.i.d. technology innovation, allow it to affect current decisions, and
exclude it from a forecasting model whose sole persistent endogenous state is
capital.

Every future result artifact should record:

- the model source path and a source-file hash;
- the named calibration variant;
- source parameter values;
- requested overrides;
- Dynare's effective calibration and version;
- normalization, learning specification, and shock normalization;
- the Git commit used to create the result.
