# EE consumption-forecast specification audit

## Question and scope

This experiment asks one narrow question: at the Eusepi–Preston benchmark
calibration, does the treatment of subjective consumption forecasts materially
change Euler-equation (EE) learning impulse responses? It is a specification
audit, not a claim that the published results used multiple forecast rules.

The comparison fixes the gain at 0.002, trains for 2,000 observations, starts
at the Dynare rational-expectations (RE) coefficients and population RLS moment
matrix, and gives both treatments the same innovation in every draw and period.
Calibration, information timing, technology-growth impulse, projection rule,
and failure policy are also common.

## The two contracts

`paper_direct_consumption` implements the forecasting contract stated after
equation (17) of the paper: agents estimate capital return, consumption, and
capital forecasting equations. The estimated consumption coefficients enter
the subjective consumption PLM used to construct the actual law of motion.

`archive_fixed_re_consumption` targets the economically active behavior of the
released dedicated Table 5 EE simulator. That code updates rental return,
wage, output, hours, utilization, and capital, but not consumption. The clean
variant estimates those six active outcomes and leaves the consumption PLM row
at its Dynare RE coefficients. It does not restore inactive archive variables
or copy the archived simulation harness.

The historical assignment audit and 5,000-draw reconstruction are preserved on
branch `codex/investigate-ep-ee-implementation`, especially commits `babf0c1`
and `ef06f55` (tag `ep-ee-implementation-audit-v1`). That evidence establishes
the released-code behavior. The present experiment instead tests whether the
behavior is quantitatively consequential in the clean current IRF engine.

## Run and inspect

From the repository root in MATLAB:

```matlab
setup_project
audit = run_ep_ee_consumption_audit();
```

This runs 100 paired draws and saves `ep_ee_consumption_audit.mat` plus three
PDF/PNG figure pairs under `results/ep_ee_consumption_audit/`. To change only
the draw count while retaining the benchmark design:

```matlab
config = ep_experiment_config();
config.draw_count = 100;
audit = run_ep_ee_consumption_audit(config,fullfile(pwd,'results','my_audit'));
```

The MAT artifact saves the complete standardized innovations and a pairing
fingerprint. `output_files.metrics` contains outcome rates, rejected-update
counts, observations reached, conditional learning-minus-RE IRFs, and full
draw-level paper-direct-minus-archive IRF differences. “Maximum wedge” means
the maximum absolute response over the saved horizon; “cumulative wedge” means
the sum of absolute responses over that horizon. Both retain each variable's
reported units.

The comparison figure is the clearest main-text evidence: it overlays the two
conditional median learning-minus-RE responses. The difference figure removes
their common RE benchmark and plots the paired median direct-minus-archive
response. Inspect the diagnostics beside either figure: a small conditional
difference is not representative if completion or projection behavior differs
substantially between treatments.

## Claim boundary

The audit can support a statement about whether fixing consumption forecasts at
RE materially changes benchmark EE IRFs. It cannot establish which unreleased
code produced the paper, identify the global stability region, or generalize
to other gains or preference calibrations. Earlier investigation results show
that nonbenchmark settings can magnify the distinction; those parameter grids
are deliberately outside this reduced audit.
