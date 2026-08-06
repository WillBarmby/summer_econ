# Model Loader

This directory is the active Dynare boundary. The loaders run Dynare in an
isolated temporary workspace and return a canonical MATLAB model contract with:

- variable, shock, and equation names;
- structural lag, current, lead, and shock matrices;
- effective calibration;
- the first-order RE decision rule; and
- stationary/deviation transformation metadata when needed.

`load_linear_dynare_model` handles explicit `model(linear)` files.
`load_nonlinear_dynare_model` asks Dynare for analytical first derivatives at
the steady state and converts them into the same structural representation.
`extract_re_law` reorders Dynare's `ghx` and `ghu` matrices into declaration
order and expands the state-only `ghx` columns into a full transition matrix.

The remaining helpers validate the contract, unpack Dynare Jacobians, manage
Dynare's global state, and calculate stationary covariances. Dynare-specific
objects should remain inside this boundary; downstream learning code should
consume the canonical contract.
