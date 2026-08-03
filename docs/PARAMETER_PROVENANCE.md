# Parameter Provenance

The clean interface separates structural calibration from experiment design.
Every saved artifact contains Dynare's effective calibration as well as the
requested experiment configuration.

| Quantity | Original E&P value | Active E&P comparison | Reason |
|---|---:|---:|---|
| Capital share | `0.34` | `0.34` | Original structural calibration |
| Depreciation | `0.025` | `0.025` | Original structural calibration |
| Discount factor | `0.99` | `0.99` | Original structural calibration |
| Gross trend growth | `exp(0.0053)` | `exp(0.0053)` | Original baseline; `1` is a documented sensitivity |
| Technology-shock SD | `exp(-0.034)` in the original IRF driver | `exp(-0.034)` for EE and IH | Common training environment |
| Constant gain | `0.002` in the benchmark | `0.002` | Common learning experiment |
| Training periods | `2000` | `2000` | Original burn-in convention |
| IRF innovation | one percentage point | one percentage point | Fixed structural shock, not output normalization |

The released Table 5 Euler-equation simulation folders use `exp(-0.144)` for
their calibrated shock standard deviation. That value remains relevant to
archive-code verification but is not used to give active EE and IH experiments
different training environments.

The active balanced-growth NK calibration is:

| Quantity | Active NK value | Role |
|---|---:|---|
| Discount factor | `0.995` | Quarterly steady-state household discounting |
| Capital share | `0.33` | Production elasticity |
| Depreciation | `0.025` | Quarterly capital depreciation |
| Rotemberg cost | `59.11` | Price-adjustment curvature |
| Gross inflation target | `1.006` | Steady-state quarterly inflation |
| Taylor inflation coefficient | `1.5` | Active baseline policy response |
| Taylor output coefficient | `0.1` | Response to stationary output relative to steady state |
| Gross trend growth | `exp(0.0053)` | Matches the active E&P trend environment |
| Technology persistence | `0` | IID baseline technology-growth shock |
| Technology scale | `0.01` | A unit innovation is one percentage point |
| Steady-state hours | `1/3` | Calibrates labor disutility |

The risk-premium shock is dormant in the baseline (`sigma_s=0`). The dedicated
risk-premium experiment sets `rho_s=0` and `sigma_s=0.01`, so its unit impulse
is also one percentage point. Its training volatility is a controlled common
scale, not an empirical estimate of the premium process.
