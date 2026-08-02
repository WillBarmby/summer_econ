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

`run_ep_initialization_sensitivity` asks whether E&P EE learning forgets its
initial forecasting coefficients. Agents begin at the Dynare RE coefficients,
one-half of those coefficients, or zero. The three treatments retain identical
structural equations, information, gain, initial RLS moment matrix, innovations,
and update timing. Defaults use nested training horizons of 0, 100, 500, and
2,000 observations, so every shorter history is a prefix of the longer one.

This is an initialization-robustness extension, not a claim that E&P used all
three priors. Its saved diagnostics include completion rates, distance from RE
beliefs, rejected capital-slope updates, observations reached, and draw-level
maximum IRF wedges. The corresponding NK runner currently compares RE and zero
initialization.

`run_ep_ih_initialization_robustness` is the targeted IH counterpart. It fixes
the standard 2,000-period training sample and constant gain `0.002`, comparing
exact Dynare RE coefficients with half of those coefficients. A single saved
innovation matrix feeds both treatments draw by draw. The artifact reports
path outcomes, rejected updates, observations reached, pre-shock belief
distance, conditional learning-minus-RE IRFs, and paired response differences.
It tests only whether this half-RE displacement is forgotten; it neither maps
the global basin of attraction nor shows that every initial condition matters.

For paper comparisons, `run_initialization_robustness` harmonizes E&P EE, E&P
IH, and NK EE over nested training periods of 0, 100, 500, and 2,000
observations. All three use exact RE and half-RE treatments, common innovation
histories, and the same draw-first statistic: each paired draw's maximum absolute
treatment difference, followed by the median across draws. The 2,000-period
panels are the main comparison; the shorter horizons support an appendix figure.
Zero initialization is outside this moderate cross-model comparison.

## Information sets

Both learning specifications treat the current technology innovation as
observed but exclude it from forecasting regressions. The paper-faithful EE
specification forecasts capital return, consumption, and capital. The IH
specification forecasts capital return, efficiency wage, and capital, then
uses subjective discounted price forecasts in the household decision rule.

Exact released-code EE equivalence remains a verification claim, not the active
EE specification used for substantive comparisons.
