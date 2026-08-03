# Reporting

This directory runs the model-independent E&P experiment, restores observable
level responses from stationary variables, summarizes completed draws while
retaining failures, and saves the common output, consumption, investment, and
hours panels. Simulation, reporting, and file output remain separate functions.
The harmonized initialization experiment keeps its paper-specific summarization
and graphing together beneath `experiments/initialization_robustness/`.

`save_ep_ee_consumption_audit` reports the paired paper-direct versus
archive-fixed consumption comparison, including failure and projection
diagnostics, conditional IRFs, horizon wedge summaries, and draw-level direct
differences.
