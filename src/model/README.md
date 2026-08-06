# Model Loader

This directory is the active Dynare boundary. The loaders run Dynare in an
isolated temporary workspace and return separate canonical MATLAB values with:

- variable, shock, and equation names;
- structural lag, current, lead, and shock matrices;
- effective calibration;
- stationary/deviation transformation metadata when needed.

`load_model` handles explicit `model(linear)` files and returns only structural
equation data. `solve_re` separately returns the declaration-ordered reduced-
form RE law. Private helpers isolate Dynare's globals and decision-rule shape.
Nonlinear loading is deferred in `ROADMAP.md` and is not represented by a
partially compatible public loader.

The remaining helpers validate the contracts and calculate stationary
covariances. Dynare-specific
objects should remain inside this boundary; downstream learning code should
consume the canonical contract.
