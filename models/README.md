# Active Models

- `ep_rbc_ee.mod` is the verified structural representation used for the
  paper-faithful one-period Euler-equation learning specification.
- `ep_rbc_ih.mod` is the verified 13-equation representation used for the E&P
  infinite-horizon learning specification.

Both are explicit linear percentage-deviation systems copied from the verified
lineage. Their learning assumptions live in MATLAB rather than inside Dynare.

- `nk_balanced_growth.mod` is the nonlinear stationary NK model transcribed
  from `docs/model_simple_dynare.tex`. Dynare computes its analytical
  first-order approximation. Its top-of-file map documents every TeX-to-Dynare
  name change, and its risk-premium shock is dormant by default.

- `old_nk.mod` is the pre-balanced-growth technology-level specification kept
  solely for historical comparison. It is not an active model and no supported
  runner loads it.
