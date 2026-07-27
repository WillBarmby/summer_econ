function run = simulate_learning(learning_model,shocks,initial_values, ...
    initial_beliefs,explosion_policy)
%% SIMULATE_LEARNING Simulate a structural model with recursively updated beliefs.
% learning_model supplies beliefs_to_plm, plm_to_alm, regressor, and outcome.
% Decisions use beliefs held at the start of the period; RLS updates afterward.
% Thus period t follows: form the subjective PLM, derive its implied ALM,
% realize y_t, check admissibility, and finally learn from (x_t,y_t). This
% decide-then-update ordering prevents current outcomes from affecting the
% decision that generated them.

validate_policy(explosion_policy);
periods = size(shocks,2)+1;
n = numel(initial_values);
values = zeros(n,periods);
values(:,1) = initial_values(:);
beliefs = initial_beliefs;
diagnostics = cell(1,periods-1);
status = "completed";
termination = empty_termination();
last_period = periods;
for t = 2:periods
    plm = learning_model.beliefs_to_plm(beliefs);
    try
        alm = learning_model.plm_to_alm(plm);
    catch exception
        % Some beliefs make the contemporaneous structural system singular.
        % This is an economically relevant invalid learning draw, not a reason
        % to abort the remaining Monte Carlo histories. Unexpected programming
        % errors are rethrown so they cannot be mislabeled as instability.
        if strcmp(exception.identifier,'EPResearch:SingularAlm') || ...
                strcmp(exception.identifier,'EPResearch:UnstableForecast')
            status = "invalid";
            criterion = "singular_alm";
            if strcmp(exception.identifier,'EPResearch:UnstableForecast')
                criterion = "unstable_forecast";
            end
            termination = make_termination(t,NaN,NaN, ...
                criterion,explosion_policy);
            last_period = t-1;
            break
        end
        rethrow(exception)
    end
    values(:,t) = alm.intercept+alm.transition*values(:,t-1)+ ...
        alm.shock_impact*shocks(:,t-1);
    monitored = explosion_policy.variable_indices;
    current = values(monitored,t);
    nonfinite = find(~isfinite(current),1);
    excessive = find(abs(current)>explosion_policy.magnitude_limit,1);
    if explosion_policy.reject_nonfinite && ~isempty(nonfinite)
        status = "explosive";
        termination = make_termination(t,monitored(nonfinite), ...
            current(nonfinite),"nonfinite",explosion_policy);
        last_period = t;
        break
    elseif ~isempty(excessive)
        status = "explosive";
        termination = make_termination(t,monitored(excessive), ...
            current(excessive),"magnitude_limit",explosion_policy);
        last_period = t;
        break
    end
    regressor = learning_model.regressor(values,t);
    outcome = learning_model.outcome(values,t);
    [beliefs,diagnostics{t-1}] = update_beliefs_rls( ...
        beliefs,regressor,outcome,learning_model.learning);
    if beliefs.invalid
        status = "invalid";
        termination = make_termination(t,NaN,NaN, ...
            "singular_moment_matrix",explosion_policy);
        last_period = t;
        break
    end
end
run = struct('native_path',values(:,1:last_period), ...
    'learning_state',beliefs, ...
    'diagnostics',{diagnostics(1:max(0,last_period-1))}, ...
    'status',status,'termination',termination, ...
    'invalid',status=="invalid",'explosive',status=="explosive");
end

function validate_policy(policy)
required = {'magnitude_limit','reject_nonfinite','variable_indices'};
assert(isstruct(policy) && isscalar(policy) && ...
    isempty(setxor(fieldnames(policy),required.')), ...
    'EPResearch:InvalidExplosionPolicy','Explosion policy is incomplete.');
assert(isnumeric(policy.magnitude_limit) && isscalar(policy.magnitude_limit) && ...
    isfinite(policy.magnitude_limit) && policy.magnitude_limit>0, ...
    'EPResearch:InvalidExplosionPolicy','Magnitude limit must be positive.');
assert(islogical(policy.reject_nonfinite) && isscalar(policy.reject_nonfinite), ...
    'EPResearch:InvalidExplosionPolicy','reject_nonfinite must be logical.');
assert(isnumeric(policy.variable_indices) && ...
    isvector(policy.variable_indices) && ~isempty(policy.variable_indices), ...
    'EPResearch:InvalidExplosionPolicy','Variable indices must be nonempty.');
end

function value = empty_termination()
value = struct('period',NaN,'variable_index',NaN,'value',NaN, ...
    'criterion',"",'policy',struct());
end

function value = make_termination(period,index,trigger,criterion,policy)
value = struct('period',period,'variable_index',index,'value',trigger, ...
    'criterion',criterion,'policy',policy);
end
