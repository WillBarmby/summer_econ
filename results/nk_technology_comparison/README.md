# NK Technology-Shock Nominal IRFs

**Question:** what are the NK real, inflation, and nominal-rate responses to a
one-percentage-point technology-growth innovation, and does one-step EE
learning change the RE benchmark?

The baseline uses 100 paired draws, 2,000 training observations, gain `0.002`,
and a 40-quarter reporting horizon. All 100 draws complete. Maximum absolute
median learning-minus-RE wedges are:

| Output | Consumption | Investment | Hours | Inflation | Nominal rate |
|---:|---:|---:|---:|---:|---:|
| 0.0015 | 0.0030 | 0.0147 | 0.0017 | 0.0002 | 0.0003 |

The RE inflation response is `0.0747` percent deviation on impact and declines
monotonically through the horizon. The nominal-rate response is `0.1011` on
impact and also declines monotonically. Thus the responses are persistent but
not hump-shaped. The main figure is
`nk_technology_comparison_panels.pdf`/`.png`; the MAT artifact and summary CSV
retain the complete paths and diagnostics.
