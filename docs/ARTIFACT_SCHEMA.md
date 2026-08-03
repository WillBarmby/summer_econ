# Result Artifact Schema

Public runners write schema-version `2.0.0` MAT artifacts and compact CSV
summaries. The MAT file preserves configuration, draw-level evidence, and
diagnostics; the CSV is the quickest route to paper-facing scalar results.

## Common top-level fields

Every public artifact contains:

- `schema_version`: the saved-data contract version.
- `experiment`: stable experiment identifier.
- `question`: the research question answered by the experiment.
- `config`: common draw, training, gain, shock, and horizon settings.
- `units`: definitions for responses, wedges, rates, and cumulative metrics.
- `periods`: MATLAB indices and economic horizons. Column 1 is impact at
  horizon 0; column `j` is `j-1` quarters after impact.
- `axes`: dimension names for experiment-specific arrays.
- `provenance`: UTC generation time, Git commit and dirty-state flag, MATLAB
  version, and generating runner.
- `summary`: paper-facing metrics and completion diagnostics.
- `output_files`: paths only, including `summary_csv`.

The files use MATLAB's `save(...,'-struct',...)` convention, so `load` returns a
scalar struct whose fields are the artifact fields:

```matlab
A = load("results/ep_comparison/ep_comparison.mat");
A.question
A.periods
A.axes
A.summary
readtable(A.output_files.summary_csv)
```

## Common simulation result

Nested learning simulations retain a shared contract:

```text
learning_draws                    draw × quantity × period
re_reported_path                 quantity × period
terminal_training_coefficients   draw × learned outcome × regressor
terminal_training_moments        draw × regressor × regressor
statuses                         draw
```

The simulation's own `axes`, `periods`, `units`, `quantity_names` from the
parent artifact, and `variable_names` define those dimensions. Failed draws
remain `NaN` in `learning_draws`; use `statuses` and `status_counts` rather than
inferring completion from a conditional median.

## Summary conventions

For ordinary learning comparisons,
`summary.maximum_absolute_median_learning_minus_re_wedge` is indexed by
`specification × quantity`. For gain experiments it is indexed by
`specification × gain × quantity`. Gain metrics are results and therefore live
under `summary`, never under `output_files`.

Rates in MAT artifacts and CSVs are fractions from zero to one. Figures may
multiply them by 100 and label them as percentages. Responses are percentage
deviations; a learning-minus-RE wedge is therefore measured in percentage
points of the reported response.

Initialization robustness has larger arrays. Its `axes` field explicitly maps
the six-dimensional draw-level IRF and all scalar summaries. The associated
CSV remains the preferred interface for specification-by-horizon comparisons.

## Compatibility boundary

Artifacts created before schema `2.0.0` remain valid historical outputs, but
their metrics may appear beneath `output_files` and their dimensions are not
self-describing. Rerun the producing public runner to create the current schema
and CSV. Code consuming saved artifacts should check `schema_version` before
assuming the version-2 field layout.
