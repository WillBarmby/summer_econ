# Active Models

- `ep_rbc_ee.mod` is the verified structural representation used for the
  paper-faithful one-period Euler-equation learning specification.
- `ep_rbc_ih.mod` is the verified 13-equation representation used for the E&P
  infinite-horizon learning specification.

Both are explicit linear percentage-deviation systems copied from the verified
lineage. Their learning assumptions live in MATLAB rather than inside Dynare.

The temporary NK model is deliberately excluded. A nonlinear stationary,
balanced-growth NK model will be added only after its transformation is derived
and reviewed.
