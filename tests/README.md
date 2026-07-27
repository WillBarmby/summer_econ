# Tests

`test_minimal_engine` currently covers model loading, RE extraction, a
hand-calculated RLS update, Jacobian layout, paired IRF timing, failure status
reporting, and complete short E&P EE/IH paths against compact verified fixtures.
`test_nonlinear_loader` verifies the NK steady state, analytical Jacobian
layout, percentage-point transformation, transformed RE law, and parameter
overrides.

`test_ep_public_interface` checks seeded reproducibility, saved metadata,
common shocks, growth sensitivity, and complete PDF/PNG output.

Public entry points are `run_fast_tests` and `run_acceptance_tests`. The fast
suite includes a one-draw graph smoke test. Acceptance compares full seeded
Monte Carlo summaries with compact fixtures from the verified lineage, without
placing the archived replication tree on the MATLAB path.
