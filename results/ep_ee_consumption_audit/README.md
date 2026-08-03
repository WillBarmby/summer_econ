# E&P EE Consumption-Forecast Audit

**Question:** does directly learning subjective consumption forecasts, as
described after equation (17), materially change benchmark EE IRFs relative to
the released-code behavior that keeps consumption forecasts at RE?

Both treatments complete 100 of 100 draws with no projection events. Maximum
absolute paired-median paper-direct-minus-archive differences are:

| Output | Consumption | Investment | Hours |
|---:|---:|---:|---:|
| 0.0053 | 0.0026 | 0.0284 | 0.0079 |

The forecast contract matters for the relatively small EE response, especially
investment, but the difference remains much smaller than the benchmark IH
amplification. Use `ep_ee_consumption_audit_diagnostics.pdf` with the comparison
and difference figures; the MAT artifact contains full draw-level diagnostics.
Use `ep_ee_consumption_audit_summary.csv` for the compact variant-by-quantity
comparison.
