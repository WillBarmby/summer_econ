# Tests

`test_minimal_engine` currently covers model loading, RE extraction, a
hand-calculated RLS update, Jacobian layout, paired IRF timing, failure status
reporting, and complete short E&P EE/IH paths against compact verified fixtures.
`test_nonlinear_loader` verifies the NK steady state, analytical Jacobian
layout, percentage-point transformation, transformed RE law, and parameter
overrides.

`test_initialization_robustness` applies that isolation check to E&P EE, E&P
IH, and NK EE, reconstructs their single common innovation matrix, and verifies
the unified MAT, CSV, and paper-figure outputs.

`test_ep_public_interface` checks seeded reproducibility, saved metadata,
common shocks, growth sensitivity, and complete PDF/PNG output.

`test_ep_ee_consumption_variants` proves the two EE treatments share the same
RE PLM before updating and satisfy their distinct consumption-row identities
after one common observation. `test_ep_ee_consumption_audit` exercises the
full paired artifact and figure path with one 2,000-observation draw.

Public entry points are `run_fast_tests` and `run_acceptance_tests`. The fast
suite includes a one-draw graph smoke test. Acceptance compares full seeded
Monte Carlo summaries with compact fixtures from the verified lineage, without
placing the archived replication tree on the MATLAB path.

The cross-model and gain-grid orchestration runners reuse tested model loaders,
learning engines, and reporting functions, but they do not yet have dedicated
committed smoke tests. They were manually smoke-tested during the August 3,
2026 documentation and runnability audit. Future changes to their artifact
schemas should add direct automated tests rather than relying on that audit.
