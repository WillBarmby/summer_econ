# E&P Gain Sensitivity

**Question:** how does responsiveness to new data alter amplification and
stability in E&P one-step EE versus infinite-horizon learning when histories
are held fixed?

Maximum median investment wedges for gains 0, 0.002, 0.005, 0.01, and 0.02 are
0, 0.0290, 0.0662, 0.1054, and 0.2161 for EE, versus 0, 1.1316, 2.6795,
5.2669, and 9.7886 for IH. The gain-0.02 IH value is conditional on 47
completed draws; 53 draws are explosive.

Use `ep_gain_sensitivity_summary.csv` for the labeled gain-by-specification
table, `ep_gain_sensitivity.mat` for draw-level evidence, and
`ep_gain_sensitivity_heatmap.pdf` for the paper-facing figure.
