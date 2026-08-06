# Roadmap

The current vertical slice targets the linear Eusepi–Preston paper-direct EE
and benchmark IH comparison. Comparison artifacts deliberately store a cell
of self-describing case artifacts. Dense views aligned across models are a
future pure-consumer feature, not part of the saved-data contract.

The next model milestone is nonlinear NK loading. It requires separately
tested analytical first-order Jacobians at steady state, explicit deviation
scales, transformed Dynare decision rules, and named materialization across
both structural shocks. `nk_ee_case` should be added only after that loader is
green. Legacy loaders, builders, simulators, and runners may be removed after
the frozen E&P parity suite passes.
