# Eusepi-Preston IR Regression Tests

This repository contains legacy MATLAB replication code. The current test
workflow focuses on the impulse-response generator and its local model files in:

```text
Eusepi_Preston_2011_Replication_Pkg/Model/Impulse-responses
```

The tests are characterization tests: they preserve the current numerical behavior
while the code is refactored. They do not prove the economics is correct; they
check that a code change did not accidentally alter the existing impulse-response
outputs.

## Files

`run_ir_baseline_artifacts.m` generates deterministic baseline artifacts from the
current impulse-response code.

`verify_ir_baseline.m` reruns the current impulse-response code and compares the
fresh output against a saved baseline artifact. This is the pass/fail test.

`baseline_ir_smoke_artifacts.mat` is the fast baseline fixture. It was generated
with 5 draws and is intended for day-to-day refactor checks.

`baseline_ir_artifacts.mat` is the stronger baseline fixture. It was generated with
100 draws and is useful before larger commits or behavior-sensitive changes.

## Run The Fast Test

From the repository root:

```bash
matlab -batch "cd('Eusepi_Preston_2011_Replication_Pkg/Model/Impulse-responses'); verify_ir_baseline('baseline_ir_smoke_artifacts.mat')"
```

Expected result:

```text
IR baseline verification passed: baseline_ir_smoke_artifacts.mat
```

If the test fails, MATLAB raises an error and exits nonzero. The error message
will indicate whether dimensions, NaN/Inf flags, or a specific IR series changed.

## Run The Stronger Test

```bash
matlab -batch "cd('Eusepi_Preston_2011_Replication_Pkg/Model/Impulse-responses'); verify_ir_baseline('baseline_ir_artifacts.mat')"
```

This takes longer because it compares against the 100-draw baseline.

## Regenerate Baselines

Regenerate the fast smoke baseline:

```bash
matlab -batch "cd('Eusepi_Preston_2011_Replication_Pkg/Model/Impulse-responses'); run_ir_baseline_artifacts(20260701, 5, 'baseline_ir_smoke_artifacts.mat')"
```

Regenerate the 100-draw baseline:

```bash
matlab -batch "cd('Eusepi_Preston_2011_Replication_Pkg/Model/Impulse-responses'); run_ir_baseline_artifacts(20260701, 100, 'baseline_ir_artifacts.mat')"
```

Only regenerate a baseline when you intentionally accept new numerical behavior.
For ordinary refactors, run `verify_ir_baseline` instead.

## What Is Checked

The verifier compares:

- number of impulse-response series,
- dimensions of each IR matrix,
- NaN flags,
- Inf flags,
- raw learning IR values,
- raw rational-expectations IR values.

The comparison tolerance defaults to `1e-10`.

## Notes

The legacy driver `Main_imp_resp_Sept_2009.m` now accepts an optional
`imp_resp_n_draws` variable. If that variable is not set, it defaults to 100 draws,
preserving the original behavior.

The smoke fixture stores its draw count in the `.mat` file, so
`verify_ir_baseline('baseline_ir_smoke_artifacts.mat')` reruns with 5 draws
automatically. The draw count is not hard-coded in the verifier.
