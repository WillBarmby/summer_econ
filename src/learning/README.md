# Learning Primitives

This directory contains the model-independent state transitions used by an
adaptive-learning experiment:

- `initialize_beliefs` creates the mutable belief state;
- `update_beliefs_rls` performs one RLS update;
- `simulate_learning` applies a PLM-to-ALM callback, realizes a path, and then
  updates beliefs;
- `simulate_paired_irf` trains once and restarts shocked and unshocked paths
  from the same terminal state;
- `set_initial_beliefs` applies a named prior treatment.

The simulator consumes a `learning_model` contract containing callbacks for
belief-to-PLM conversion, PLM-to-ALM conversion, regressors, and observed
outcomes. It does not know the equations of a particular economic model.

The current implementation assumes RLS and a decide-then-update timing rule.
Those assumptions belong in the future learning-specification compiler rather
than in model-specific code.
