# Reporting

This directory runs the model-independent E&P experiment, restores observable
level responses from stationary variables, summarizes completed draws while
retaining failures, and saves the common output, consumption, investment, and
hours panels. Simulation, reporting, and file output remain separate functions.

`save_ep_ih_initialization_robustness` keeps the IH experiment runner focused
on simulation. It derives outcome rates, belief and rejected-update diagnostics,
conditional learning-minus-RE paths, and draw-paired initialization differences,
then writes the MAT manifest and two focused figures.
