# Tests

`test_minimal_engine` currently covers model loading, RE extraction, a
hand-calculated RLS update, Jacobian layout, paired IRF timing, failure status
reporting, and complete short E&P EE/IH paths against compact verified fixtures.

`test_ep_public_interface` checks seeded reproducibility, saved metadata,
common shocks, growth sensitivity, and complete PDF/PNG output. Phase 4 will
group these checks into the public fast and acceptance suites.
