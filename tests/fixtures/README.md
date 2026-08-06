# Numerical Fixtures

`ep_engine_reference.mat` contains structural matrices, RE laws, one fixed shock
sequence, and a historical short learning-path comparison generated from the
verified implementation at commit `ea47484`. It is retained as provenance while
the generic loader and engine tests are rebuilt; it is not a current experiment
output contract.

The former experiment-summary fixture has been removed with the paper-specific
acceptance suite. New fixtures should test the canonical model, learning, and
artifact contracts directly rather than preserve runner-specific schemas.
