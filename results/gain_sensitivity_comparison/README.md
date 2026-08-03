# Cross-Model Gain Sensitivity

**Question:** is technology-shock gain sensitivity common to E&P EE, E&P IH,
and NK EE, or concentrated in the infinite-horizon formulation?

The table reports the maximum absolute median investment wedge and completed
draws; all histories are paired across gains and specifications.

| Gain | E&P EE | E&P IH | NK EE | IH completed |
|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 | 100/100 |
| 0.002 | 0.0290 | 1.1316 | 0.0147 | 100/100 |
| 0.005 | 0.0662 | 2.6795 | 0.0344 | 100/100 |
| 0.01 | 0.1054 | 5.2669 | 0.0587 | 100/100 |
| 0.02 | 0.2161 | 9.7886 | 0.0982 | 47/100 |

Wedges rise with gain in every model, but IH is much more sensitive. At gain
`0.02`, 53 IH draws are explosive, so its median is conditional on the 47
completed draws. See `gain_sensitivity_comparison.mat` for all quantities and
`gain_sensitivity_comparison_heatmap.pdf` for the summary figure.
