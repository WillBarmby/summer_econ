# Experiment Design

## E&P comparison

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
and runs E&P only.

## Initialization sensitivity

`run_initialization_robustness` harmonizes E&P EE, E&P
IH, and NK EE over nested training periods of 0, 100, 500, and 2,000
observations. All three use exact RE and half-RE treatments, common innovation
histories, and the same draw-first statistic: each paired draw's maximum absolute
treatment difference, followed by the median across draws. The 2,000-period
panels are the main comparison; the shorter horizons support an appendix figure.
This moderate displacement is not a claim that E&P used both priors, a map of
the global basin of attraction, or evidence that every initial condition matters.

## Information sets

Both learning specifications treat the current technology innovation as
observed but exclude it from forecasting regressions. The paper-faithful EE
specification forecasts capital return, consumption, and capital. The IH
specification forecasts capital return, efficiency wage, and capital, then
uses subjective discounted price forecasts in the household decision rule.

Exact released-code EE equivalence remains a verification claim, not the active
EE specification used for substantive comparisons.
