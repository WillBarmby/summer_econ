# Experiment Design

## E&P comparison

**Research question:** holding the RBC structure and shock history fixed, how
do RE, paper-direct one-step EE learning, and verified IH learning differ after
a technology-growth shock?

The first clean experiment compares three expectation treatments within the
Eusepi-Preston RBC environment:

- rational expectations (RE);
- paper-faithful one-period Euler-equation learning (EE); and
- the verified infinite-horizon learning formulation (IH).

EE and IH receive the same standardized training innovations, technology-shock
standard deviation, random seed, training length, gain, and one-percentage-point
technology-growth impulse. Their shocked and unshocked IRF paths restart from
the same trained state.

The default experiment uses 100 draws, 2,000 training periods, a constant gain
of `0.002`, 40 reported quarters, and the original E&P deterministic gross
growth rate `exp(0.0053)`.

The separate deterministic-growth sensitivity changes only gross trend growth
from `exp(0.0053)` to one. It retains IID stochastic technology-growth shocks
and runs E&P only. Its question is whether the positive balanced-growth trend,
rather than the expectations formulation, drives the reported E&P differences.

## Cross-model comparison

**Research question:** when E&P and NK receive identical technology
innovations and experiment settings, how do their within-model learning-minus-
RE wedges compare?

`run_cross_model_comparison` reports both a five-path overlay and within-model
wedges. The overlay describes total model predictions; it does not isolate
expectations because the E&P and NK structural equations differ. The wedge
panels subtract each model's own RE path and are therefore the controlled
expectations comparison.

## Gain sensitivity

**Research questions:** how does responsiveness to new observations alter
amplification and stability in E&P EE and IH; how does it affect NK EE under
technology and risk-premium shocks; and is the cross-model ranking robust over
a common gain grid?

The E&P, NK, and combined runners use gains `[0 .002 .005 .01 .02]` and reuse
the same innovation histories in every cell. Gain zero is an identity check:
RE-initialized fixed beliefs reproduce RE. Failed paths are retained in status
counts rather than redrawn. In particular, the E&P IH gain-`0.02` cell is a
stress case with only 47 completed draws; its conditional median must not be
presented without that completion rate.

## NK risk-premium comparison

**Research question:** does one-step EE learning materially alter real and
nominal NK responses to an IID one-percentage-point risk-premium innovation?

Technology shocks are fixed at zero. The premium process is deliberately IID,
and the common training scale is illustrative rather than empirically
estimated. This experiment isolates a second shock-transmission channel; it is
not part of the E&P technology-shock comparison.

## NK technology-shock nominal IRFs

**Research question:** what are the NK real, inflation, and nominal-rate
responses to a one-percentage-point technology-growth innovation, and does
one-step EE learning change the RE benchmark?

`run_nk_technology_comparison` uses the baseline NK EE specification and the
same paired-draw, training, reporting, and completion conventions as the other
experiments. It restores the cumulative technology trend for output,
consumption, and investment, while retaining inflation and the nominal rate as
gross-steady-state percentage deviations. The technology shock is active and
the risk-premium shock is held exactly at zero. The resulting six-panel figure
is a standalone NK nominal companion to the four-quantity E&P–NK comparison.

## Initialization sensitivity

**Research question:** how much do learning IRFs depend on exact-RE versus
half-RE starting coefficients, and how quickly do common training histories
remove that dependence?

`run_initialization_robustness` harmonizes E&P EE, E&P
IH, and NK EE over nested training periods of 0, 100, 500, and 2,000
observations. All three use exact RE and half-RE treatments, common innovation
histories, and the same draw-first statistic: each paired draw's maximum absolute
treatment difference, followed by the median across draws. The 2,000-period
panels are the main comparison; the shorter horizons support an appendix figure.
This moderate displacement is not a claim that E&P used both priors, a map of
the global basin of attraction, or evidence that every initial condition matters.

## EE consumption-forecast audit

**Research question:** does the paper-direct subjective consumption forecast
produce materially different benchmark EE IRFs from the released-code behavior
that leaves consumption forecasts fixed at RE?

The two treatments use identical innovations, calibration, initialization,
gain, timing, projection, and failure policy. This is a specification audit;
it does not claim that the paper used two forecast rules. See
`EE_CONSUMPTION_SPECIFICATION_AUDIT.md` for the implementation evidence and
claim boundary.

## Information sets

Both learning specifications treat the current technology innovation as
observed but exclude it from forecasting regressions. The paper-faithful EE
specification forecasts capital return, consumption, and capital. The IH
specification forecasts capital return, efficiency wage, and capital, then
uses subjective discounted price forecasts in the household decision rule.

Exact released-code EE equivalence remains a verification claim, not the active
EE specification used for substantive comparisons.

Numerical findings for every experiment are reported in
`RESULTS_AND_QUESTIONS.md`; this file defines the controlled designs.
