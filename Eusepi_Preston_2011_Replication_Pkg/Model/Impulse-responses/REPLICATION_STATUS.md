# Eusepi-Preston Replication Status

This document records the verified foundation for the next research phase. It
distinguishes exact numerical replication of released code from a
paper-faithful interpretation and from new experiments.

## Verified baseline: infinite-horizon learning

The 13-equation Dynare model in `harness/models/ep13_ih_re_linear.mod` and its
named learning specification in `config/ep_ih_learning_config.m` reproduce the
released Eusepi-Preston infinite-horizon impulse-response implementation.

The verification boundary includes:

- the rational-expectations structural solution;
- the paper's three-equation perceived law of motion;
- the mapping from arbitrary stable beliefs to the actual law of motion;
- subjective wage and capital-return present values;
- recursive least-squares updates along nonzero-shock paths; and
- reported paired impulse-response quantities.

The path and arbitrary-belief comparisons use a numerical tolerance of
`1e-10`. The original archive did not record an RNG seed, so the claim is
conditional numerical equivalence under shared innovations, not recovery of
the archive's unidentified historical random draws.

Run the focused checks with:

```matlab
setup_ir_paths
test_dynare_ih_learning_adapter
test_ep_learning_path
```

The main Git milestones are:

- `a51a30e` - validate the Eusepi-Preston infinite-horizon representation;
- `3e5d727` - drive IH beliefs from Dynare equations;
- `c2dcf20` - match the paper's three-equation perceived law of motion; and
- `c95cd82` - close the Phase 1 replication cleanup.

## Euler-equation learning: two distinct claims

The released Eusepi-Preston Euler-equation code and the paper's written
description are not treated as identical.

### Released-code equivalence

`ep_ee_learning_config("archive", gain)` reproduces the released EE code's
effective forecasting structure. Given the same innovations, the generic and
Dynare-backed implementations reproduce the archived EE learning path to
`1e-10`.

```matlab
test_ep_ee_learning_path
test_ep_ee_dynare_learning_path
```

The corresponding Git milestone is `4d54476` (archive EE learning-path parity).

### Paper-faithful EE interpretation

`ep_ee_learning_config("paper", gain)` implements the statement following the
paper's equation (17): agents directly forecast consumption, capital return,
and capital. Tests establish that the named forecasting contract is present
and that subjective consumption beliefs affect the actual law of motion.

```matlab
test_ep_ee_paper_specification
```

This is a paper-faithful reimplementation, not a claim of numerical path
equivalence to the released EE code. Commit `6f96256` introduced the explicit
paper/archive distinction. New EE-versus-IH and later NK comparisons use the
paper-faithful specification, while the archive variant remains a verification
oracle.

## Deterministic-growth sensitivity

`run_ep_steady_growth_test` compares the baseline gross trend growth
`exp(0.0053)` with gross trend growth equal to one. Both calibrations receive:

- the same one-percentage-point structural technology-growth innovation;
- the same standardized random draws;
- the same E&P training-shock standard deviation, `exp(-0.034)`; and
- 100 draws with 2,000 training periods under the default configuration.

All 100 EE and IH draws in the saved artifact completed, with no explosive or
invalid paths. Removing deterministic growth has less than a one-percent
relative effect on the maximum output response. It modestly lowers the
consumption response and raises investment and hours; the largest relative
changes are approximately six to seven percent. The qualitative RE, EE, and IH
comparison is unchanged.

Run the experiment with:

```matlab
artifact = run_ep_steady_growth_test();
```

The canonical saved result is
`artifacts/comparisons/ep_steady_growth_test/ep_steady_growth_test.mat`; the
companion difference figure is saved as PDF and PNG in the same directory.

This experiment sets deterministic growth to one but retains IID stochastic
technology-growth innovations. It does not eliminate technological progress.

## Active research boundary

The following are extensions rather than replication claims:

- putting E&P EE and IH in a common shock environment;
- setting deterministic E&P growth to one;
- the nonlinear New Keynesian model and its first-order Dynare loader;
- New Keynesian Euler-equation learning; and
- the planned balanced-growth New Keynesian technology specification.

This commit is intended as the pause point before simplifying the active
research interface. Git history and the milestones above retain the complete
verification lineage even if legacy and verification code later moves out of
the normal model-running path.
