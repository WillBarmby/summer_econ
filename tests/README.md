# Active tests

The active test suite is organized around the four public handoffs:

```text
model file -> structural model -> RE solution
                         \-> learning system -> experiment result
```

`run_core_tests` discovers MATLAB `matlab.unittest` classes below `tests/unit`.

The tests are organized in this order:

1. RE-law and structural-matrix contracts;
2. model loading and Dynare failure boundaries;
3. learning compilation and specification validation;
4. experiment timing, histories, and failure statuses.

`tests/fixtures/` contains tiny model files and frozen numerical values.
`run_acceptance_tests` separately runs the slower E&P legacy-parity suite.
