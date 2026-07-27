# NK Monetary-Policy Rule Notes

This note explains the monetary-policy rule inherited from the original New
Keynesian model and records why the balanced-growth rewrite uses a simpler
baseline output target. It is background documentation rather than part of the
formal model specification.

## Original rule

The original model wrote the gross nominal interest rate as

\[
r_t=\max\left\{
1,\;
r^*\left(\frac{\pi_t}{\pi^*}\right)^{\phi_\pi}
\left(\frac{y_t}{y_t^*}\right)^{\phi_y}
\right\}.
\]

This is a nonlinear Taylor rule:

- \(r^*\) is the steady-state nominal-rate intercept.
- \(\pi_t/\pi^*\) measures gross inflation relative to its target.
- \(y_t/y_t^*\) measures output relative to the central bank's output target.
- \(\phi_\pi\) and \(\phi_y\) determine the strength of the two policy
  responses.
- The outer maximum imposes \(r_t\geq1\). Because \(r_t\) is a gross rate,
  this is a zero lower bound on the corresponding net nominal rate.

When inflation and output equal their targets, the unconstrained rule gives
\(r_t=r^*\).

## The two original output-target interpretations

The original document allowed either a constant steady-state target,

\[
y_t^*=\bar y,
\]

or a flexible-price (natural) output target,

\[
y_t^n=(\chi\mu)^{-1/(1+\eta)}z_t.
\]

With the constant target, policy responds to output moving away from its steady
state. With the natural-output target, policy instead responds to an output gap:
actual output relative to the output that the simpler economy would produce
without nominal rigidity.

The displayed natural-output formula came from the labor-only model. In that
model, flexible-price output could be reduced to a direct function of technology,
labor preferences, and the markup. It is not the natural-output allocation of
the capital model: with predetermined capital, flexible-price output also
depends on the capital state. In addition, the balanced-growth rewrite replaces
the stationary technology level \(z_t\) with stochastic technology growth.

The rewritten baseline therefore uses

\[
y_t^*=\bar y.
\]

This is a stationary and internally defined target. A future output-gap
experiment would require solving the full capital model's flexible-price
allocation and introducing that solution as a separate target process.

## ZLB choice in the comparison model

The smooth baseline comparison removes the outer `max` operator. This matches
the intended implementation without a zero lower bound and lets Dynare analyze
a differentiable policy equation around the steady state. Restoring the ZLB is
not merely a parameter change: it creates a piecewise equation and should be
treated as a separate nonlinear experiment with an appropriate solution method.
