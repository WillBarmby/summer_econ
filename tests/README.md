# Tests

`test_minimal_engine` currently covers model loading, RE extraction, a
hand-calculated RLS update, Jacobian layout, paired IRF timing, failure status
reporting, and complete short E&P EE/IH paths against compact verified fixtures.

Phase 3 will connect these checks to the public fast and acceptance runners and
add experiment artifact and graph tests.
