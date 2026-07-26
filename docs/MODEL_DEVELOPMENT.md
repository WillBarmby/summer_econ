# Model Development Rules

## Future balanced-growth NK model

The temporary NK technology-level specification is not part of the clean
interface. Its replacement will use labor-augmenting technology and stationary
variables normalized by the stochastic technology level, matching the economic
environment of the E&P comparison.

The economic transformation must be derived and reviewed before coding:

- define the technology level and gross technology growth;
- specify the timing of consumption, output, investment, capital, and wages in
  efficiency units;
- derive normalized equilibrium conditions and the balanced-growth steady
  state; and
- state agents' information and forecasting assumptions independently of the
  structural equations.

The production Dynare file will contain the nonlinear stationary model. Dynare
will compute its analytical first-order approximation. MATLAB may then perform
a small, explicit conversion from additive deviations to log/proportional
deviations. A separate hand-linearized production model will not be maintained.

Hand calculations and finite-difference tests will verify economically important
rows such as production, resource balance, capital accumulation, technology
growth, and the Taylor rule.
