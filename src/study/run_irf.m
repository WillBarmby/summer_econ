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
baseline = run_experiment(system,baseline_spec);
shocked = run_experiment(system,shocked_spec);
[status,termination] = combined_status(baseline,shocked);
primitive_irf = shocked.path-baseline.path;
native_irf = primitive_irf(:,2:end);
re_native = re_irf(prepared.learning_system,design.periods,impulse);
[reported,series] = apply_reporting(native_irf,prepared);
[re_reported,~] = apply_reporting(re_native,prepared);
stored_design = design; stored_design.baseline_shocks = future;
stored_design.shocked_shocks = shocked_shocks;
artifact = struct('schema_version',"3.0",'kind',"irf", ...
    'case',training.case,'model',training.model, ...
    'learning_specification',training.learning_specification, ...
    'reporting_specification',prepared.reporting_specification, ...
    'training_reference',struct('case_fingerprint', ...
        training.provenance.case_fingerprint,'innovation_fingerprint', ...
        training.provenance.innovation_fingerprint,'terminal',training.terminal), ...
    'irf_design',stored_design,'baseline',baseline,'shocked',shocked, ...
    'primitive_irf',primitive_irf,'native_irf',native_irf, ...
    'reported_irf',reported,'re_native_path',re_native, ...
    're_reported_path',re_reported,'series',series, ...
    'status',status,'termination',termination, ...
    'axes',struct('primitive_irf',{{'native_variable','primitive_time'}}, ...
        'native_irf',{{'native_variable','horizon'}}, ...
        'reported_irf',{{'series','horizon'}}, ...
        're_native_path',{{'native_variable','horizon'}}, ...
        're_reported_path',{{'series','horizon'}}), ...
    'units',struct('native_irf',"model_units",'horizon',"periods"), ...
    'timing',struct('primitive_path',"[y0,y1,...,yT]", ...
        'irf_columns',"primitive columns 2:end",'horizons',0:design.periods-1), ...
    'provenance',struct('generator',"run_irf", ...
        'case_fingerprint',case_fingerprint(prepared), ...
        'innovation_fingerprint',design.innovation_fingerprint));
validate_artifact(artifact);
end

function value = experiment(initial,shocks,policy,history)
value = struct('initial_values',initial,'shocks',shocks,'periods',size(shocks,2), ...
    'explosion_policy',policy,'store_belief_history',history);
end
function [status,termination] = combined_status(baseline,shocked)
status = "completed"; termination = struct();
if baseline.status~="completed"
    status = baseline.status; termination = baseline.termination; termination.stage = "baseline";
elseif shocked.status~="completed"
    status = shocked.status; termination = shocked.termination; termination.stage = "shocked";
end
end
function path = re_irf(system,periods,impulse)
alm = system.plm_to_alm(system.belief_to_plm(system.initial_beliefs));
path = zeros(numel(system.variable_names),periods);
if periods==0, return; end
path(:,1) = alm.intercept+alm.shock*impulse;
for t=2:periods, path(:,t)=alm.intercept+alm.transition*path(:,t-1); end
end
function [values,series] = apply_reporting(native,prepared)
series = prepared.reporting_specification.series;
names = prepared.structural_model.variable_names;
values = zeros(numel(series),size(native,2));
for j=1:numel(series)
    [~,index]=ismember(string(series(j).variable),string(names));
    value=native(index,:);
    for k=1:numel(series(j).cumulative_variables)
        [~,c]=ismember(string(series(j).cumulative_variables{k}),string(names));
        value=value+cumsum(native(c,:),2);
    end
    values(j,:)=series(j).scale*value;
end
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
