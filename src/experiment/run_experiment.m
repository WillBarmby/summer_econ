function result = run_experiment(learning_system,experiment_specification)
%% RUN_EXPERIMENT Simulate one path under recursively updated beliefs.
% Period t uses beginning-of-period beliefs to form a PLM and ALM, realizes
% y_t from shock t, applies the explosion policy, and only then updates.

validate_learning_system(learning_system);
validate_experiment_specification(experiment_specification);
validate_handoff(learning_system,experiment_specification);

n = numel(learning_system.variable_names);
periods = experiment_specification.periods;
path = NaN(n,periods+1);
path(:,1) = experiment_specification.initial_values(:);
plm_history = cell(1,periods);
alm_history = cell(1,periods);
diagnostics = cell(1,periods);
belief_history = cell(0,0);
beliefs = learning_system.initial_beliefs;
if experiment_specification.store_belief_history
    belief_history = cell(1,periods+1);
    belief_history{1} = beliefs;
end

status = "completed";
termination = struct();
for period = 1:periods
    plm = learning_system.belief_to_plm(beliefs);
    plm_history{period} = plm;
    try
        alm = learning_system.plm_to_alm(plm);
    catch exception
        [expected,criterion] = expected_alm_failure(exception.identifier);
        if ~expected
            rethrow(exception)
        end
        status = "invalid";
        termination = make_termination( ...
            period,criterion,NaN,"",NaN);
        break
    end
    validate_alm(alm,n,numel(learning_system.shock_names));
    alm_history{period} = alm;
    path(:,period+1) = alm.intercept+ ...
        alm.transition*path(:,period)+ ...
        alm.shock*experiment_specification.shocks(:,period);

    [violated,termination] = check_explosion( ...
        path(:,period+1),period,learning_system.variable_names, ...
        experiment_specification.explosion_policy);
    if violated
        status = "explosive";
        break
    end

    regressor = learning_system.regressor(path,period+1);
    outcome = learning_system.outcome(path,period+1);
    [beliefs,diagnostics{period}] = learning_system.updater( ...
        beliefs,regressor,outcome);
    if beliefs.invalid
        status = "invalid";
        termination = make_termination( ...
            period,"singular_moment_matrix",NaN,"",NaN);
        break
    end
    if experiment_specification.store_belief_history
        belief_history{period+1} = beliefs;
    end
end

result = struct( ...
    'path',path, ...
    'belief_history',{belief_history}, ...
    'plm_history',{plm_history}, ...
    'alm_history',{alm_history}, ...
    'diagnostics',{diagnostics}, ...
    'terminal_beliefs',beliefs, ...
    'status',status, ...
    'termination',termination);
end

function validate_handoff(system,specification)
n = numel(system.variable_names);
q = numel(system.shock_names);
if numel(specification.initial_values)~=n
    error('AdaptiveLearning:InvalidExperimentSpecification', ...
        'Initial values must contain one value per model variable.');
end
if ~isequal(size(specification.shocks),[q specification.periods])
    error('AdaptiveLearning:InvalidShockSchedule', ...
        'Shock rows must match the compiled system shock declarations.');
end
if any(specification.explosion_policy.variable_indices>n)
    error('AdaptiveLearning:InvalidExperimentSpecification', ...
        'Explosion policy contains an out-of-range variable index.');
end
end

function validate_alm(alm,n,q)
if ~isstruct(alm) || ~isscalar(alm) || ...
        ~all(isfield(alm,{'intercept','transition','shock'})) || ...
        ~finite_matrix(alm.intercept,[n 1]) || ...
        ~finite_matrix(alm.transition,[n n]) || ...
        ~finite_matrix(alm.shock,[n q])
    error('AdaptiveLearning:InvalidLearningSystem', ...
        'Compiled PLM-to-ALM mapping returned an invalid law.');
end
end

function result = finite_matrix(value,expected_size)
result = isnumeric(value) && isreal(value) && ...
    isequal(size(value),expected_size) && all(isfinite(value),'all');
end

function [expected,criterion] = expected_alm_failure(identifier)
switch identifier
    case 'AdaptiveLearning:SingularALM'
        expected = true;
        criterion = "singular_alm";
    case 'AdaptiveLearning:UnstableForecast'
        expected = true;
        criterion = "unstable_forecast";
    otherwise
        expected = false;
        criterion = "";
end
end

function [violated,termination] = check_explosion( ...
    current,period,variable_names,policy)
violated = false;
termination = struct();
indices = policy.variable_indices(:);
values = current(indices);
if policy.reject_nonfinite
    local_index = find(~isfinite(values),1);
    if ~isempty(local_index)
        index = indices(local_index);
        violated = true;
        termination = make_termination(period,"nonfinite",index, ...
            string(variable_names(index)),values(local_index));
        return
    end
end
local_index = find(abs(values)>policy.magnitude_limit,1);
if ~isempty(local_index)
    index = indices(local_index);
    violated = true;
    termination = make_termination(period,"magnitude_limit",index, ...
        string(variable_names(index)),values(local_index));
end
end

function value = make_termination(period,criterion,index,name,trigger)
value = struct( ...
    'period',period, ...
    'criterion',criterion, ...
    'variable_index',index, ...
    'variable_name',name, ...
    'value',trigger);
end
