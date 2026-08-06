# Learning Primitives

This directory contains the model-independent state transitions used by an
adaptive-learning experiment:

- `compile_learning` resolves a declarative specification into callbacks;
- `initialize_learning_beliefs` privately creates the mutable belief state;
- `update_beliefs_rls` performs one RLS update;
- `run_experiment` owns the primitive simulation loop;
- `run_training_irf` composes training and paired paths from the same terminal
  values and beliefs;
- `set_initial_beliefs` applies a named prior treatment.

The simulator consumes a `learning_system` contract containing callbacks for
belief-to-PLM conversion, PLM-to-ALM conversion, regressors, and observed
outcomes. It does not know the equations of a particular economic model.

The current compiler supports RLS and a decide-then-update timing rule. Those
choices remain explicit in the declarative learning specification.
