# Experiment Questions and Headline Results

## How to read the numbers

Unless stated otherwise, results use 100 paired draws, 2,000 training
observations, a constant gain of `0.002`, a one-percentage-point innovation,
and a 40-quarter reporting horizon. Reported real quantities are level
responses reconstructed from stationary model variables. A "maximum wedge" is
the maximum over the reported horizon of the absolute pointwise median
learning-minus-own-RE impulse response. It is not a maximum over individual
draws.

The default quantity order in the tables is output, consumption, investment,
and hours. Values retain the models' reported percentage-deviation units.

## Headline findings

1. The expectations formulation is quantitatively decisive. At the benchmark
   gain, E&P one-step EE and NK one-step EE remain close to their own RE
   benchmarks, while E&P IH produces much larger wedges over the reported
   horizon.
2. Higher gain increases amplification in every specification. E&P IH is the
   most gain-sensitive and becomes fragile at gain `0.02`: only 47 of 100
   draws complete, while 53 are classified as explosive.
3. The paper-direct treatment of subjective consumption forecasts matters for
   E&P EE responses, especially investment, even though both EE variants remain
   much closer to RE than IH at the benchmark.
4. Removing deterministic trend growth changes the E&P responses, particularly
   investment, but does not explain the large EE-IH difference.
5. Starting beliefs matter at short training horizons. After 2,000 observations,
   IH has largely forgotten a half-RE displacement, whereas E&P EE and NK EE
   retain economically important initialization effects.
6. NK risk-premium learning effects are modest at the benchmark gain and rise
   steadily with the gain.

## Experiment catalog

### `run_ep_comparison`

**Question.** Holding the E&P RBC structure and shock history fixed, how do RE,
paper-direct one-step EE learning, and verified IH learning change the response
to a technology-growth shock?

**Result.** All EE and IH draws complete. Maximum median learning-minus-RE
wedges are:

| Specification | Output | Consumption | Investment | Hours |
|---|---:|---:|---:|---:|
| E&P EE | 0.0053 | 0.0028 | 0.0290 | 0.0081 |
| E&P IH | 0.2095 | 0.1055 | 1.1316 | 0.3151 |

The verified infinite-horizon formulation, rather than adaptive updating by
itself, is the principal source of the large benchmark amplification.

### `run_cross_model_comparison`

**Question.** Under identical technology innovations and experiment settings,
are learning wedges similar in the E&P RBC and balanced-growth NK structures?

**Result.** All five paths complete 100 of 100 draws. NK EE maximum wedges are
0.0015, 0.0030, 0.0147, and 0.0017. Thus E&P EE and NK EE are both close to
their own RE benchmarks, while E&P IH is much farther away. Direct E&P-versus-
NK path differences still combine structural and expectations differences;
the within-model wedges are the controlled comparison.

### `run_ep_growth_sensitivity`

**Question.** Are the E&P learning results driven by the original positive
deterministic growth rate rather than by the expectations formulation?

**Result.** Setting gross trend growth from `exp(0.0053)` to one changes the
maximum absolute median learning response by 0.0093, 0.0268, 0.1555, and
0.0299 for EE, and by 0.0108, 0.0384, 0.2311, and 0.0447 for IH. Growth changes
quantitative magnitudes but does not overturn the much larger IH benchmark
wedge.

### `run_ep_gain_sensitivity`

**Question.** How does responsiveness to new data alter amplification and
stability in E&P EE and IH when all histories are held fixed?

**Result.** Maximum wedges rise with gain in both formulations, but much more
rapidly in IH. The investment wedge rises from 0.0290 to 0.2161 for EE and from
1.1316 to 9.7886 for IH between gains `0.002` and `0.02`. The gain-`0.02` IH
statistic is conditional on 47 completed draws and must be reported with its 53
explosive draws.

### `run_gain_sensitivity_comparison`

**Question.** Is gain sensitivity common to E&P EE, E&P IH, and NK EE under the
same technology shock, or concentrated in one formulation?

**Result.** Wedges increase with gain in all three rows. IH is much more
sensitive than either one-step specification. All E&P EE and NK EE cells
complete 100 draws; every IH cell through gain `0.01` completes 100 draws, but
gain `0.02` completes 47.

### `run_nk_risk_premium_comparison`

**Question.** Does one-step EE learning materially change the NK response to an
IID one-percentage-point risk-premium innovation when technology shocks are
zero?

**Result.** All 100 draws complete. At gain `0.002`, maximum wedges for output,
consumption, investment, hours, inflation, and the nominal rate are 0.0069,
0.0018, 0.0279, 0.0103, 0.0024, and 0.0035. The experiment is an illustrative
shock-transmission comparison, not an empirical calibration of the premium
process.

### `run_nk_technology_comparison`

**Question.** What are the NK real, inflation, and nominal-rate responses to a
one-percentage-point technology-growth innovation, and does one-step EE
learning change the RE benchmark?

**Result.** The technology shock generates positive inflation and nominal-rate
responses that peak immediately on impact and then decay. The baseline IRF is
persistent but not hump-shaped: neither inflation nor the nominal rate rises
to a later peak. The standalone six-panel figure reports these nominal paths
together with the four real quantities.

### `run_nk_gain_sensitivity`

**Question.** How does the learning gain affect NK EE amplification under
separate technology and risk-premium shocks?

**Result.** Every technology and risk-premium cell completes 100 draws. For the
risk-premium shock, the investment wedge rises from 0.0279 at gain `0.002` to
0.1849 at gain `0.02`; the other real and nominal wedges also rise. Technology
and premium results are kept separate because their shock transmission differs.

### `run_initialization_robustness`

**Question.** How much do reported learning IRFs depend on starting at exact RE
rather than half-RE coefficients, and how quickly does training remove that
dependence?

**Result.** All cases complete with no projection events. At 2,000 observations,
the median retained coefficient displacement is 48.8 percent for E&P EE, 17.7
percent for E&P IH, and 27.4 percent for NK EE. The initialization effect is
about 17 times the small RE-initialized learning wedge for E&P EE and 18-24
times for NK EE, but only about 5 percent of the ordinary IH learning effect.
This is a moderate two-prior comparison, not a global stability result.

### `run_ep_ee_consumption_audit`

**Question.** Does directly learning a subjective consumption equation, as
described after equation (17), materially change benchmark EE IRFs relative to
the released-code behavior that keeps consumption forecasts at RE?

**Result.** Both treatments complete 100 draws with no projection events. The
maximum absolute paired-median direct-minus-archive differences are 0.0053,
0.0026, 0.0284, and 0.0079. The specification distinction is consequential for
the relatively small EE wedge, particularly investment, but it does not approach
the size of the benchmark IH amplification.

## Claim boundaries

These experiments compare model-implied impulse responses under controlled
simulation designs. They do not estimate the models, establish empirical fit,
map global stability regions, or prove that one expectations mechanism is the
historically correct description of beliefs. Conditional medians must always be
reported with completion and projection diagnostics when failures occur.
