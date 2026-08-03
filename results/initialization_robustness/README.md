# Initialization Robustness

**Question:** how much do learning IRFs depend on exact-RE versus half-RE
starting coefficients, and how quickly does training remove that dependence?

The experiment uses 100 paired draws and nested training histories of 0, 100,
500, and 2,000 observations. At 2,000 observations:

| Specification | Initial displacement retained | Initialization effect relative to ordinary learning effect |
|---|---:|---:|
| E&P EE | 48.8% | about 17 times |
| E&P IH | 17.7% | about 5% |
| NK EE | 27.4% | about 18-24 times |

All cases complete and no projection events occur. IH largely forgets the
moderate prior relative to its large learning effect; E&P EE and NK EE remain
prior-sensitive relative to their small RE-initialized wedges. See
`initialization_robustness_summary.csv` for every quantity and horizon.
