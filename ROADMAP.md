# Roadmap

The current vertical slice targets the linear Eusepi–Preston paper-direct EE
and benchmark IH comparison. Comparison artifacts deliberately store a cell
of self-describing case artifacts. Dense views aligned across models are a
future pure-consumer feature, not part of the saved-data contract.

The active model milestone is nonlinear NK loading. Its contract requires the
same analytical-Jacobian path as linear models, evaluated at steady state,
with explicit deviation scales and transformed Dynare decision rules. Named
materialization across both structural shocks already exists. `nk_ee_case`
should be added only after the nonlinear loader and RE handoff are green.
