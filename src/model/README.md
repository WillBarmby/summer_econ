# Model Engine

This directory contains separate Dynare 7.1 loaders for explicit-linear models
and stationary nonlinear models. `load_nonlinear_dynare_model` asks Dynare for
analytical first derivatives and converts additive level deviations into an
explicitly documented percentage-point canonical system. The directory also
contains structural-model validation, RE decision-rule extraction, Jacobian
layout checks, and stationary covariance calculation.
