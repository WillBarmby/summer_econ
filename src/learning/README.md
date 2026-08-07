# Learning Primitives

This directory contains the model-independent state transitions used by an
adaptive-learning experiment:

- `compile_learning` resolves a declarative specification into callbacks;
- `initialize_learning_beliefs` privately creates the mutable belief state;
- `validate_learning_specification` checks declarative learning inputs;
- `validate_learning_system` checks the compiled learning handoff.

The simulator consumes a `learning_system` contract containing callbacks for
belief-to-PLM conversion, PLM-to-ALM conversion, regressors, and observed
outcomes. It does not know the equations of a particular economic model.

The current compiler supports RLS and a decide-then-update timing rule. Those
choices remain explicit in the declarative learning specification. Prior
treatments belong in `initialization.coefficients.scale`; compiled systems are
not mutated after construction.
