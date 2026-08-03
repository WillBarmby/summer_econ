# Learning Engine

This directory contains model-independent RLS updates, adaptive-learning path
simulation, paired IRF construction, and the compilers that join an economic
learning specification to a structural model.

The simulation engine consumes a `learning_model` contract rather than knowing
about E&P equations directly. Model-specific economics remain in the compilers
and expectation mappings.

For E&P EE experiments, `build_ee_learning_model` validates the named
consumption-forecast rule. Undeclared PLM rows remain at their RE values, which
makes the archive-fixed treatment explicit without importing archive row
numbers or inactive variables.
