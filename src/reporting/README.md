# Reporting

This directory contains the common reporting layer for E&P and NK experiments.
It restores observable level responses from stationary variables, summarizes
completed draws while retaining failures, and saves common real-quantity and
NK nominal-quantity panels. Simulation, summarization, and file output remain
separate functions. The harmonized initialization experiment keeps its
paper-specific draw-first metrics and graphing beneath
`experiments/initialization_robustness/`.

Cross-model overlays are descriptive; the corresponding learning-minus-own-RE
panels are the controlled expectations comparison. Gain heatmaps report
conditional median wedges and must be read with completion counts, especially
for E&P IH at gain `0.02`.

`save_ep_ee_consumption_audit` reports the paired paper-direct versus
archive-fixed consumption comparison, including failure and projection
diagnostics, conditional IRFs, horizon wedge summaries, and draw-level direct
differences.
