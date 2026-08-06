# Generalized experiment engine

This document is the active contract for the generalized engine. Historical
experiment documentation under `docs/` is retained for provenance and is not
authoritative for these interfaces.

## Public pipeline

```matlab
structural_model = load_model(model_file, model_options);
re_solution = solve_re(structural_model);

learning_system = compile_learning( ...
    structural_model, re_solution, learning_specification);

simulation_result = run_experiment( ...
    learning_system, experiment_specification);
```

The handoffs are deliberately separate:

```text
model file
    -> structural_model
    -> re_solution
    -> learning_system
    -> simulation_result
```

`learning_specification` and `experiment_specification` are inputs to the
compiler and runner respectively. No stage returns a generic artifact bundle
containing the inputs or private state of another stage.

## Contract values

### `structural_model`

Required fields:

```text
current, lag, lead, shock
variable_names, shock_names, equation_names
calibration, transformation
```

The three endogenous matrices are `n`-by-`n`; `shock` is `n`-by-`q`; and the
name lists identify the same declaration order used by every downstream
value. Matrix entries must be finite real numbers. Calibration and
transformation are scalar metadata structs.

The structural model contains the equation-residual representation only. It
must not contain `re`, Dynare decision-rule objects, learning beliefs,
learning callbacks, shock schedules, output paths, or reporting settings.

### `re_solution`

Required fields:

```text
intercept, transition, shock
state_indices, variable_names, shock_names
```

`intercept` is `n`-by-1, `transition` is `n`-by-`n`, and `shock` is `n`-by-`q`.
`state_indices` contains unique valid endogenous-variable indices. The name
lists preserve the structural-model declaration order. This value contains a
reduced-form RE law, not Dynare's global state or decision-rule object.

### `learning_specification`

This is declarative input, not executable machinery. It contains:

```text
learned_variables, regressors, gain
initialization, update_timing, projection
```

It identifies what the researcher wants learned. It must not contain a model
copy, function handles, closures, shock schedules, output paths, or reporting
settings.

### `learning_system`

Required fields:

```text
initial_beliefs
belief_to_plm, plm_to_alm, regressor, outcome, updater
```

This is the only handoff that combines structural and learning details. It
contains compiled learning machinery only. It must not contain an experiment
shock schedule, output path, or reporting configuration.

### `experiment_specification`

Required fields:

```text
initial_values, shocks, periods
explosion_policy, store_belief_history
```

The v1 timing convention is:

```text
initial_values = y_0
shocks         = q-by-periods
path           = [y_0, y_1, ..., y_periods]
```

Each shock column produces one simulated period. `periods` is a
nonnegative integer equal to the number of shock columns. The specification
does not construct PLMs or ALMs.

### `simulation_result`

Outputs remain separate by meaning:

```text
path, belief_history, plm_history, alm_history
diagnostics, status, termination
```

Expected runtime failures are represented by `status` and `termination`.
Configuration and handoff errors are exceptions.

## Validation and error policy

The eventual validators are single-value functions that return no value on
success and throw a typed MATLAB exception on failure:

```matlab
validate_structural_model(structural_model)
validate_re_solution(re_solution)
validate_learning_system(learning_system)
validate_experiment_specification(experiment_specification)
```

The canonical identifiers are:

```text
AdaptiveLearning:InvalidStructuralModel
AdaptiveLearning:InvalidRESolution
AdaptiveLearning:InvalidLearningSystem
AdaptiveLearning:InvalidExperimentSpecification
AdaptiveLearning:InvalidLearningSpecification
AdaptiveLearning:UnknownVariable
AdaptiveLearning:InvalidShockSchedule
```

The red contract suite specifies these behaviors before the implementations
are migrated. Existing `EPResearch:*` identifiers are legacy behavior and do
not define the new interface.

## Test order

Tests proceed from pure values to external boundaries:

1. structural-model and RE-solution contracts;
2. model loading and Dynare failure boundaries;
3. learning compilation and specification validation;
4. experiment timing, histories, and runtime failure statuses.

The first phase intentionally leaves the suite red. It does not modify the
current loaders, learning engine, simulator, or existing validators.
