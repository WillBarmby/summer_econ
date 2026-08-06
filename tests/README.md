# Active tests

The active test suite is organized around the four public handoffs:

```text
model file -> structural model -> RE solution
                         \-> learning system -> experiment result
```

`run_core_tests` discovers MATLAB `matlab.unittest` classes below `tests/unit`.

The tests will be built in this order:

1. RE-law and structural-matrix contracts;
2. model loading and Dynare failure boundaries;
3. learning compilation and specification validation;
4. experiment timing, histories, and failure statuses.

`tests/fixtures/` contains tiny model files and numerical fixtures used by
those tests. 

`test_minimal_engine.m` and `test_nonlinear_loader.m` are
transitional function tests for the current implementation. 
I will delete them following successful reworking of this codebase.