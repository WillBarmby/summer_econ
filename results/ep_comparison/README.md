# E&P RE, EE, and IH Comparison

**Question:** holding the E&P RBC structure and shock history fixed, how do RE,
paper-direct one-step EE learning, and verified infinite-horizon (IH) learning
change the response to a technology-growth shock?

The saved benchmark uses 100 paired draws, 2,000 training observations, gain
`0.002`, and 40 reported quarters. The table reports the maximum over the
horizon of the absolute median learning-minus-own-RE response.

| Specification | Output | Consumption | Investment | Hours | Completed |
|---|---:|---:|---:|---:|---:|
| E&P EE | 0.0053 | 0.0028 | 0.0290 | 0.0081 | 100/100 |
| E&P IH | 0.2095 | 0.1055 | 1.1316 | 0.3151 | 100/100 |

IH produces substantially larger amplification than one-step EE. Primary files:
`ep_comparison.mat` and `ep_comparison_panels.pdf`.
