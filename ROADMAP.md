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

## Research-experiment migration backlog

The generalized engine is active before every historical paper runner has been
migrated. The following outputs remain planned consumers of the current case,
study, artifact, and reporting contracts:

- [ ] E&P comparison runner and `ep_comparison_panels.pdf`;
- [ ] cross-model runner and `learning_wedges.pdf`;
- [ ] gain-sensitivity sweep and `gain_sensitivity_comparison_heatmap.pdf`;
- [ ] initialization-robustness runner and its IRF/summary panels;
- [ ] remaining growth, risk-premium, consumption-audit, and initialization
  experiments.

Each migration should be a thin experiment-folder manifest plus a reporting
consumer. Historical results and the tagged pre-packaging release remain the
reference until the corresponding parity test is added.
