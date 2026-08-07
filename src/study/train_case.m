function artifact = train_case(prepared,design)
%% TRAIN_CASE Run one training history and expose a reusable terminal state.

validate_prepared(prepared);
validate_training_design(design);
if size(design.standardized_innovations,1)~=1
    error('AdaptiveLearning:InvalidStudyDesign', ...
        'train_case requires exactly one innovation row.');
end
n = numel(prepared.learning_system.variable_names);
shocks = materialize_named_shocks(prepared.learning_system.shock_names, ...
    design.shock_name,design.standardized_innovations,design.standard_deviation);
policy = design.explosion_policy;
policy.variable_indices = 1:n;
specification = struct('initial_values',resolve_initial_values( ...
    design.initial_values,n),'shocks',shocks,'periods',design.periods, ...
    'explosion_policy',policy,'store_belief_history',design.store_belief_history);
result = run_experiment(prepared.learning_system,specification);
last = find(any(isfinite(result.path),1),1,'last');
terminal = struct('values',result.path(:,last), ...
    'beliefs',result.terminal_beliefs);
stored_design = design;
stored_design.shocks = shocks;
artifact = build_training_artifact(prepared,design,stored_design,result,terminal);
end

function values = resolve_initial_values(value,n)
if (ischar(value) || isstring(value)) && string(value)=="zeros"
    values = zeros(n,1);
elseif isnumeric(value) && isreal(value) && numel(value)==n && all(isfinite(value))
    values = value(:);
else
    error('AdaptiveLearning:InvalidStudyDesign','Invalid training initial values.');
end
end

function validate_prepared(value)
required = {'id','label','structural_model','re_solution','learning_specification', ...
    'learning_system','reporting_specification'};
if ~isstruct(value) || ~isscalar(value) || ~all(isfield(value,required))
    error('AdaptiveLearning:InvalidPreparedCase','Invalid prepared case.');
end
end

function validate_training_design(value)
required = {'explosion_policy';'initial_values';'innovation_fingerprint'; ...
    'periods';'shock_name';'standard_deviation'; ...
    'standardized_innovations';'store_belief_history'};
if ~isstruct(value) || ~isscalar(value) || ...
        ~isequal(sort(fieldnames(value)),required) || ...
        ~isequal(size(value.standardized_innovations,2),value.periods)
    error('AdaptiveLearning:InvalidStudyDesign','Invalid training design.');
end
end
