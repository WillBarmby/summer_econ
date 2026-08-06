# Roadmap

The current vertical slice targets the linear Eusepi–Preston paper-direct EE
and benchmark IH comparison. Comparison artifacts deliberately store a cell
of self-describing case artifacts. Dense views aligned across models are a
future pure-consumer feature, not part of the saved-data contract.

Nonlinear NK loading and the first `nk_ee_case` are now green. The loader uses
the shared analytical-Jacobian path at steady state, explicit deviation
scales, and transformed Dynare decision rules. A compact one-draw technology
experiment matches the former `main` implementation exactly.

The next NK extensions are a named risk-premium case and an aligned
cross-model consumer for quantities shared by E&P and NK. Those additions
should remain case/reporting configuration above the existing engine.
