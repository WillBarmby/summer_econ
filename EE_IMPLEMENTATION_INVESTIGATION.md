# Eusepi-Preston EE Implementation Investigation

## Status

This note records evidence, not a final allegation. The question is whether
the released code for the Euler-equation (EE) rows of Table 5 implements the
paper's statement that households directly forecast their own future
consumption.

Investigation branch: `codex/investigate-ep-ee-implementation`

Historical source snapshot: commit `08d2f09b97576e43938e67090448222a10b28e3d`
(`first commit`). This is the first repository commit containing the imported
E&P replication package.

## What the paper says

Immediately after equation (17), the paper says that the EE decision rule
requires households to directly forecast their own future consumption using
regressions of the kind specified in Section II. Section II's regressions use
a constant and aggregate capital as the forecasting variables.

## What the dedicated Table 5 archive does

The early snapshot contains two dedicated EE simulation directories, separate
from the impulse-response directory:

- `simulation_codes_Euler_sg_162`: gain 0.002.
- `simulation_codes_Euler_162`: gain 0.04.

In both directories:

- `bus_cycle_stats_fun.m` sets `param(1)=0`, selecting the EE model.
- `main_stats.m` generates 5,000 samples of length 5,162 and calls
  `bus_cycle_stats_fun.m`.
- `Model_Simul_Oct_2009.m` identifies consumption as row 12.
- The simulator sets `n_eq=7`.
- Its RLS target is `Y_var(1:n_eq,t)`.
- Feedback writes updated coefficients only to PLM rows `1:n_eq`.

The updated rows are rental return, wage, bond return, output, hours,
utilization, and capital. Consumption is not among them. No assignment to the
consumption PLM row was found anywhere in either dedicated EE directory,
including the `.asv` files.

The EE model matrix nevertheless places expected future consumption in the
consumption equation. The consumption PLM row is initialized from RE and, on
the evidence found so far, remains there during learning.

## Evidence that these directories generated the reported experiment

Each dedicated EE directory includes `results_RBC_162.mat`. File metadata says
the workspaces were created on November 14, 2009 on Linux. Both contain 5,000
draws, matching `main_stats.m`.

The stored Monte Carlo means are:

| Moment | Gain 0.002 | Gain 0.04 | Published Table 5 |
|---|---:|---:|---:|
| Relative consumption volatility | 0.536661 | 0.536126 | 0.54 / 0.54 |
| Relative investment volatility | 2.425517 | 2.425036 | 2.43 / 2.43 |
| Relative hours volatility | 0.493582 | 0.493220 | 0.49 / 0.49 |
| Consumption-growth autocorrelation | 0.079409 | 0.076292 | 0.08 / 0.08 |
| Output-growth autocorrelation | -0.005899 | 0.001517 | -0.01 / 0.00 |
| Investment-growth autocorrelation | -0.031741 | -0.018869 | -0.03 / -0.02 |
| One-quarter forecast-error autocorrelation | -0.001602 | 0.092085 | 0.00 / 0.09 |

This close agreement strongly indicates that the dedicated directories and
their saved workspaces are the source of the published EE rows, or at minimum
an implementation numerically equivalent to the source. Absolute output
volatility differs by a scale factor (stored value about 1.07 versus published
1.31), which remains to be explained.

## Relationship to the IH simulator

The dedicated small-gain EE `Model_Simul_Oct_2009.m` is effectively copied
from an IH simulation directory. A direct comparison with
`simulation_codes_gamma_0020_162` finds only two differences:

1. a stale/mismatched function declaration name; and
2. the accepted gain ceiling is raised from 0.025 to 0.075.

The RLS target selection and feedback loops were not adapted for direct
consumption learning. The EE economic equation is selected instead by the
parameter passed from `bus_cycle_stats_fun.m`.

The `.asv` file retains the old 0.025 gain ceiling, but the executable `.m`
file uses 0.075. Therefore the published gain 0.04 is accepted. The earlier
suspicion that the released executable rejects 0.04 is not supported.

## Repository-history result

Git history shows the dedicated EE simulator entering at `08d2f09` and being
removed during the later file-structure cleanup at `645b30a`. There is no
intervening commit that changes its `n_eq=7`, RLS target, or feedback rows.
Thus the possible mismatch predates the current refactor and Dynare work.

## Competing interpretations to test

1. **Implementation mismatch.** The EE switch was added to an IH simulator
   without changing the learned outcomes to include consumption.
2. **Implicit wage proxy.** Because consumption and wages are nearly identical
   under the benchmark calibration, the authors may have intended learned wage
   beliefs to stand in for consumption beliefs. No explicit mapping has yet
   been found.
3. **Unreleased final code.** The published table may have used a different
   final implementation. The close match between saved 5,000-draw workspaces
   and the table makes a materially different implementation less likely, but
   does not rule it out.
4. **Numerical robustness.** The code may differ from the written description
   without materially changing the benchmark-gain conclusion.

## Completed implementation and audit

The static assignment audit now accounts for every write to `OMEGA_0`,
`OMEGA_c`, and `Regressors`, as well as returned aliases and MATLAB value
semantics. It confirms that released archive EE cannot change consumption row
12 after RE initialization. The executable `.m`, autosaves, numbered PTL
copies, and MAT schemas contain no alternate consumption update. See
`artifacts/investigation/historical/ep_ee_plm_assignment_audit.md`.

The archived workspaces have been reconstructed directly into machine-readable
MAT/CSV/Markdown artifacts. Their stored means match exactly and seven Table 5
entries match after published rounding. No checked transformation explains the
absolute output-volatility discrepancy, so it remains explicitly unresolved.

The modern harness now names three EE interpretations: `archive` (consumption
fixed at RE), `paper` (direct consumption learning), and `wage_proxy` (an
explicit wage-to-consumption coefficient copy). Optional belief histories
record consumption/wage intercepts, capital slopes, forecasts, and update
status. Tests establish the intended update identities and show that changing
expected consumption changes the EE ALM.

The Dynare loader now renders a temporary canonical model for an explicit
`sigma`, asserts exactly one calibration replacement, and records the loaded
calibration. Matched Monte Carlo uses identical innovations and preserves
explosive/invalid draws instead of zero-filling them.

## 1,000-draw pilot result

At `sigma=1`, gain 0.002, all specifications completed all 1,000 draws. At
gain 0.04, archive completed all draws while paper and wage proxy each had 12
explosions. Their completed-draw moment differences from RE were modest but
statistically distinguishable for several moments.

At `sigma=2`, gain 0.002, all specifications again completed all draws. At
gain 0.04 the archive implementation exploded in all 1,000 draws, while paper
and wage proxy completed all 1,000. Moreover, paper and wage proxy are no
longer quantitatively interchangeable: their output-volatility means were
approximately 0.902 and 1.938, respectively. This confirms that the benchmark
near-identity of consumption and wages can conceal an economically important
specification difference.

The 5,000-draw definitive experiment is required before turning this pilot
result into a paper claim.

## Current claim boundary

Supported now:

> The released, dedicated EE Table 5 code appears not to update the subjective
> consumption forecasting equation described after equation (17), and its
> saved results closely reproduce the published EE moments.

Also supported by the implementation diagnostics and pilot:

> Direct consumption learning, explicit wage-proxy learning, and consumption
> fixed at RE are distinct specifications. A non-unit intertemporal-elasticity
> calibration makes those distinctions quantitatively large.

Not yet supported:

> Eusepi and Preston's published conclusion is wrong because of a coding error.

That stronger claim requires the matched 5,000-draw result and still must be
qualified by the unresolved possibility of unreleased final code.
