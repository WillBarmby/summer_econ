# Model Loader

This directory is the active Dynare boundary. The loaders run Dynare in an
isolated temporary workspace and return separate canonical MATLAB values with:

- variable, shock, and equation names;
- structural lag, current, lead, and shock matrices;
- effective calibration;
- stationary/deviation transformation metadata when needed.

`load_model` handles both explicit `model(linear)` files and stationary
nonlinear models. Both use Dynare's generated analytical dynamic Jacobian;
the nonlinear path additionally resolves and applies declared deviation
scales at the deterministic steady state. `solve_re` separately returns the
declaration-ordered reduced-form RE law in those same units. Private helpers
isolate Dynare's globals and decision-rule shape.

The remaining helpers validate the contracts and calculate stationary
covariances. Dynare-specific
objects should remain inside this boundary; downstream learning code should
consume the canonical contract.
