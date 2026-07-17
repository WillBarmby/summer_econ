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

## Next evidence steps

1. Trace every assignment to the full PLM matrices in the early snapshot and
   prove whether row 12 can change indirectly.
2. Compare `.m`, `.asv`, `.ptl`, and any saved coefficient workspaces for an
   alternate consumption-learning implementation.
3. Reconstruct the stored 5,000-draw Table 5 means from the archived workspace
   and explain the output-volatility scale discrepancy.
4. Add a diagnostic test that records the consumption and wage PLM
   coefficients period by period under archive EE.
5. Add an explicit wage-to-consumption proxy variant alongside archive EE and
   direct-consumption EE.
6. Run matched 1,000- and 5,000-draw comparisons with uncertainty intervals.
7. Test a calibration with `sigma` different from one to break the approximate
   consumption-wage identity.

## Current claim boundary

Supported now:

> The released, dedicated EE Table 5 code appears not to update the subjective
> consumption forecasting equation described after equation (17), and its
> saved results closely reproduce the published EE moments.

Not yet supported:

> Eusepi and Preston's published conclusion is wrong because of a coding error.

That stronger claim requires completion of the alternative-implementation and
large-sample robustness tests above.
