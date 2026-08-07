function artifact = run_irf(prepared,training,design)
%% RUN_IRF Evaluate paired paths from a reusable completed training artifact.

validate_artifact(training);
if training.kind~="training" || training.status~="completed"
    error('AdaptiveLearning:IncompatibleHandoff', ...
        'IRF evaluation requires a completed training artifact.');
end
if training.provenance.case_fingerprint~=case_fingerprint(prepared)
    error('AdaptiveLearning:IncompatibleHandoff', ...
        'Training artifact belongs to a different prepared case.');
end
validate_irf_design(design);
if size(design.standardized_innovations,1)~=1
    error('AdaptiveLearning:InvalidStudyDesign', ...
        'run_irf requires exactly one innovation row.');
end
system = prepared.learning_system;
system.initial_beliefs = training.terminal.beliefs;
future = materialize_named_shocks(system.shock_names,design.shock_name, ...
    design.standardized_innovations,design.standard_deviation);
impulse = materialize_named_shocks(system.shock_names,design.shock_name,1,design.impulse);
shocked_shocks = future;
shocked_shocks(:,1) = shocked_shocks(:,1)+impulse;
n = numel(system.variable_names);
policy = design.explosion_policy; policy.variable_indices = 1:n;
baseline_spec = experiment(training.terminal.values,future,policy, ...
    design.store_belief_history);
shocked_spec = experiment(training.terminal.values,shocked_shocks,policy, ...
    design.store_belief_history);
paired = run_paired_paths(system,training.terminal.values, ...
    baseline_spec,shocked_spec);
primitive_irf = paired.irf;
native_irf = primitive_irf(:,2:end);
re_native = re_irf(prepared.learning_system,design.periods,impulse);
[reported,series] = apply_reporting_specification(native_irf, ...
    prepared.structural_model.variable_names,prepared.reporting_specification);
[re_reported,~] = apply_reporting_specification(re_native, ...
    prepared.structural_model.variable_names,prepared.reporting_specification);
stored_design = design; stored_design.baseline_shocks = future;
stored_design.shocked_shocks = shocked_shocks;
artifact = build_irf_artifact(prepared,training,design,stored_design, ...
    paired,primitive_irf,native_irf,reported,re_native,re_reported,series);
end

function value = experiment(initial,shocks,policy,history)
value = struct('initial_values',initial,'shocks',shocks,'periods',size(shocks,2), ...
    'explosion_policy',policy,'store_belief_history',history);
end
function path = re_irf(system,periods,impulse)
alm = system.plm_to_alm(system.belief_to_plm(system.initial_beliefs));
path = zeros(numel(system.variable_names),periods);
if periods==0, return; end
path(:,1) = alm.intercept+alm.shock*impulse;
for t=2:periods, path(:,t)=alm.intercept+alm.transition*path(:,t-1); end
end
function validate_irf_design(value)
required = {'explosion_policy';'impulse';'innovation_fingerprint';'periods'; ...
    'shock_name';'standard_deviation';'standardized_innovations'; ...
    'store_belief_history'};
if ~isstruct(value)||~isscalar(value)||~isequal(sort(fieldnames(value)),required)|| ...
        value.periods<1||size(value.standardized_innovations,2)~=value.periods
    error('AdaptiveLearning:InvalidStudyDesign','Invalid IRF design.');
end
end
