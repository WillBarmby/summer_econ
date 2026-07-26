# Parameter Provenance

The clean interface separates structural calibration from experiment design.
Every saved artifact will contain Dynare's effective calibration as well as the
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

The future NK calibration will record original source values and active common
experiment values in separate columns before any cross-model results are run.
