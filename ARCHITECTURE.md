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

#### Dynare linearization contract

Both explicit `model(linear)` sources and stationary nonlinear sources use
Dynare's generated analytical first-order dynamic Jacobian. A shared extractor
maps its dense declaration-ordered columns into `lag`, `current`, `lead`, and
`shock` blocks. The linear backend evaluates at zero deviations and uses unit
endogenous scales. The nonlinear backend evaluates at Dynare's deterministic
steady state and applies the change of variables

```text
x = x_bar + diag(deviation_scales) * y.
```

Positive steady-state variables default to `x_bar/100`, so one unit of `y` is
one percentage-point proportional deviation. Every variable with a zero or
nonpositive steady state requires an explicit positive `deviation_scales`
entry. Shock units remain those declared by the `.mod` file. Transformation
metadata records the level steady state, resolved scales, and scale overrides.

The nonlinear loader returns only transformed structural derivatives. At the
separate RE boundary, Dynare's level decision rule is transformed as

```text
transition = S^(-1) * transition_level * S
shock      = S^(-1) * shock_level.
```

No level decision rule or Dynare runtime object crosses either boundary.

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
estimator, initialization, update_timing, projection, expectation_mapping
```

It identifies what the researcher wants learned and how those beliefs enter
the model. It must not contain a model copy, function handles, closures, shock
schedules, output paths, experiment labels, or reporting settings.

`learned_variables` is a nonempty list of unique endogenous names. Variables
not listed here retain their RE perceived-law rows; the compiler must never
silently replace them with learned coefficients.

`regressors` is an ordered cell array of named declarative descriptors. The
v1 descriptor kinds are:

```matlab
struct('name',"constant",'kind',"constant")
struct('name',"capital_lag",'kind',"lagged_variable", ...
    'variable',"capital",'lag',1)
```

Names are unique and become the column labels of the coefficient matrix.
Lagged-variable descriptors must name a structural-model variable and use a
positive integer lag. Function handles and arbitrary expressions are not
valid regressors. This representation covers the constant-and-lagged-capital
PLMs used by the retained E&P and NK experiments while leaving room for later
descriptor kinds.

`gain` selects the RLS gain schedule. V1 supports:

```matlab
struct('type',"constant",'value',0.002)
struct('type',"decreasing",'offset',500)
```

A constant gain is finite and nonnegative; zero is valid and freezes beliefs
for RE equivalence tests. A decreasing-gain offset is finite and nonnegative.

`estimator` makes numerically consequential RLS conventions explicit:

```matlab
struct( ...
    'method',"rls", ...
    'moment_timing',"update_before_coefficients", ...
    'rcond_tolerance',1e-12)
```

V1 supports RLS only. The timing value means the period-t regressor moment is
updated before it is used in the period-t coefficient update, matching the
retained implementation. The reciprocal-condition tolerance is a finite
positive scalar. Keeping it declarative permits exact reproduction of older
specifications that used different tolerances without creating separate
updater functions.

`initialization` has separate coefficient and regressor-moment policies:

```matlab
struct( ...
    'coefficients',struct('method',"re",'scale',1), ...
    'moments',struct('method',"stationary_re", ...
        'shock_covariance',Sigma))
```

The coefficient scale supports exact-RE (`1`), half-RE (`0.5`), and zero
(`0`) treatments without modifying a compiled system after the fact. The
stationary moment policy uses the supplied finite positive-semidefinite
`q`-by-`q` innovation covariance and the RE law to initialize regressor
moments. Explicit coefficient or moment initializations may be added later as
new discriminated methods; they must not be inferred from field shape.

`update_timing` is `"decide_then_update"` in v1: period-t decisions use the
beliefs held at the beginning of the period, and the realized period-t
observation updates beliefs afterward.

`projection` is either empty or a declarative rule (or rule array):

```matlab
struct( ...
    'variable',"capital", ...
    'regressor',"capital_lag", ...
    'criterion',"absolute_limit", ...
    'limit',0.99, ...
    'action',"retain_previous_coefficient")
```

The variable must be learned and the regressor must be declared. Projection
changes only the named candidate coefficient, leaving other updates from the
same observation intact.

`expectation_mapping` selects the named PLM-to-ALM compiler strategy. It is
declarative so the old one-step EE and infinite-horizon E&P experiments do not
require different public compiler functions:

```matlab
struct('method',"one_step",'options',struct())

struct('method',"infinite_horizon",'options',struct( ...
    'discount',beta_tilda, ...
    'present_values',struct( ...
        'target',{'rk','wage'}, ...
        'variable',{'rk_sum','w_sum'}, ...
        'equation',{'capital_pv','wage_pv'}, ...
        'target_scale',{1,1}), ...
    'decision',struct( ...
        'equation',"ih_consumption", ...
        'remove_variables',{{'rk_sum','w_sum'}}, ...
        'forecast_targets',{{'gamma_x','rk','wage'}}, ...
        'forecast_weights',decision_weights), ...
    'feedback',true))
```

Strategy options contain names and scalar settings only. The compiler resolves
those names against the structural model and creates the executable mapping.
`decision_weights` are the coefficients multiplying discounted forecast sums
after any model-specific normalization. This keeps calibration formulas in a
model-specific specification builder rather than hard-coding E&P formulas in
the generalized compiler. Unknown methods or names are configuration errors.

### `learning_system`

Required fields:

```text
variable_names, shock_names
learned_variables, regressor_names
initial_beliefs
belief_to_plm, plm_to_alm, regressor, outcome, updater
```

This is the only handoff that combines structural and learning details. It
contains compiled learning machinery only. It must not contain an experiment
shock schedule, output path, or reporting configuration.

The name lists make the compiled system inspectable and give the experiment
boundary endogenous and shock dimensions without embedding a structural-model
copy. If `m` variables are learned from `k` regressors, initial coefficients
are `m`-by-`k` and the initial regressor-moment matrix is `k`-by-`k`.

The executable fields have fixed v1 signatures:

```matlab
plm = learning_system.belief_to_plm(beliefs)
alm = learning_system.plm_to_alm(plm)
x_t = learning_system.regressor(path,t)
y_t = learning_system.outcome(path,t)
[beliefs,diagnostic] = learning_system.updater(beliefs,x_t,y_t)
```

A PLM contains `intercept` and `transition`. An ALM contains `intercept`,
`transition`, and `shock`, using the same declaration order as the model and
RE solution. The compiler fills unlearned PLM rows from the RE solution and
replaces only coefficients named by the learning specification.

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

For period `t = 1,...,periods`, the engine performs:

```text
beliefs at start of t -> PLM_t -> ALM_t -> y_t -> belief update
```

Thus decisions never use the observation they generate. `path` is always
`n`-by-`(periods+1)`; after early termination its unproduced columns are
`NaN`. `plm_history`, `alm_history`, and `diagnostics` are 1-by-`periods`
cell arrays. When requested, `belief_history` is 1-by-`(periods+1)`, with the
initial beliefs first and each successful post-observation update following.
Otherwise `belief_history` is empty. Unreached history entries remain empty.

### `simulation_result`

Outputs remain separate by meaning:

```text
path, belief_history, plm_history, alm_history
diagnostics, terminal_beliefs, status, termination
```

Expected runtime failures are represented by `status` and `termination`.
Configuration and handoff errors are exceptions.

Completed runs have status `"completed"` and an empty termination struct.
Expected numerical failures use status `"invalid"`; policy violations use
`"explosive"`. A termination record identifies `period`, `criterion`,
`variable_index`, `variable_name`, and triggering `value`. Unexpected
programming exceptions are rethrown rather than mislabeled as runtime state.

### Training and paired IRF composition

Training and impulse-response comparison compose the primitive rather than
introducing another simulation loop:

```matlab
paired_result = run_training_irf(learning_system,struct( ...
    'training',training_experiment, ...
    'baseline',baseline_experiment, ...
    'shocked',shocked_experiment));
```

The terminal training values and beliefs initialize both branches. Baseline
and shocked specifications have matching periods and declared initial values;
the declared values establish compatibility before training and are replaced
by the shared terminal training state for the composed branches. Their full shock
schedules may differ. `paired_result.irf` is `shocked.path-baseline.path`,
including the common initial-value column. The result preserves all three
primitive runs and adds only aggregate `status` and staged `termination`.

## Artifacts and reporting

Simulation, artifact assembly, and reporting are separate operations:

```matlab
simulation_result = run_experiment(learning_system,experiment_specification);
artifact = assemble_artifact(structural_model,learning_specification, ...
    experiment_specification,simulation_result);
figures = generate_figures(artifact,reporting_specification);
```

`run_experiment` does not save files or draw figures. `assemble_artifact`
extracts nonexecutable model metadata and preserves the declarative
specifications, innovations, statuses, paths, beliefs, and diagnostics needed
for reproducibility. It does not copy structural matrices or compiled
callbacks. Reporting consumes that artifact and may apply the structural
model's transformation metadata, but reporting choices do not flow backward
into the model, learning, or simulation values.

The initial reporting API is:

```matlab
report = report_artifact(artifact,reporting_specification);
figure_handle = generate_artifact_figure(artifact,reporting_specification);
```

## Case and comparison toolkit

Model-specific choices sit above, and do not alter, the stable core pipeline:

```matlab
definition = ep_ee_case(options);
prepared = prepare_case(definition);
single = run_case(prepared,one_draw_design);
comparison = run_comparison({prepared,other_case},shared_design);
```

A case definition contains identity, model source/options, a learning-
specification factory, and a declarative reporting specification. Preparation
exposes every core handoff. Study designs identify shocks by economic name;
materialization resolves model declaration order and leaves all unselected
shock rows at zero.

`run_case` returns a `training_irf` artifact with full primitive histories.
`run_comparison` returns a `comparison` artifact whose `cases` are compact
`case_collection` artifacts. Collections retain native and reported IRFs,
statuses and terminations, terminal coefficients and moments, projection
counts, RE benchmarks, and pointwise summaries. They do not retain compiled
callbacks, structural matrices, or every period's histories.

Primitive paired IRFs include the shared initial state. Study artifacts expose
columns `2:end`, so their first column is impact horizon zero. Saving and
export remain separate from all execution and reporting functions.

The specification selects source `"path"` or `"irf"` and declares plotted
series by output name, native variable, cumulative addends, and scale. A
reported series is

```text
scale * (native variable + sum(cumsum(cumulative variables)))
```

This covers stationary-to-level transformations such as adding cumulative
technology growth without embedding E&P-specific variable choices in the
reporter. Figure generation is in-memory; saving and file naming are separate
caller responsibilities.

## Validation and error policy

The eventual validators are single-value functions that return no value on
success and throw a typed MATLAB exception on failure:

```matlab
validate_structural_model(structural_model)
validate_re_solution(re_solution)
validate_learning_specification(learning_specification)
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
AdaptiveLearning:UnknownName
AdaptiveLearning:InvalidShockSchedule
AdaptiveLearning:IncompatibleHandoff
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
