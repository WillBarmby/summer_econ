function run = simulate_learning_path(plugin, shocks, initial_y, initial_learning, explosion_policy)
%% SIMULATE_LEARNING_PATH Generic adaptive-learning simulation.
%
% A plugin supplies beliefs_to_plm, plm_to_alm, regressor, and outcome.

validate_explosion_policy(explosion_policy);
T = size(shocks,2)+1;
n = numel(initial_y);
y = zeros(n,T); y(:,1) = initial_y(:);
beliefs = initial_learning;
diagnostics = cell(1,T-1);
belief_distance = NaN(1,T-1);
plm_roots = NaN(1,T-1);
alm_roots = NaN(1,T-1);
status = "completed";
termination = empty_termination();
last_period = T;
for t = 2:T
    plm = plugin.beliefs_to_plm(beliefs);
    alm = plugin.plm_to_alm(plm);
    y(:,t) = alm.intercept+alm.transition*y(:,t-1)+alm.shock_impact*shocks(:,t-1);
    monitored = explosion_policy.variable_indices;
    current = y(monitored,t);
    nonfinite = find(~isfinite(current),1);
    excessive = find(abs(current)>explosion_policy.magnitude_limit,1);
    if explosion_policy.reject_nonfinite && ~isempty(nonfinite)
        status = "explosive";
        termination = make_termination(t,monitored(nonfinite),current(nonfinite), ...
            "nonfinite",explosion_policy);
        last_period = t;
        break
    elseif ~isempty(excessive)
        status = "explosive";
        termination = make_termination(t,monitored(excessive),current(excessive), ...
            "magnitude_limit",explosion_policy);
        last_period = t;
        break
    end
    x = plugin.regressor(y,t);
    target = plugin.outcome(y,t);
    [beliefs,diagnostics{t-1}] = update_rls(beliefs,x,target,plugin.learning);
    if beliefs.invalid
        status = "invalid";
        termination = make_termination(t,NaN,NaN,"singular_moment_matrix",explosion_policy);
        last_period = t;
        break
    end
    plm_roots(t-1) = max(abs(eig(plm.transition)));
    alm_roots(t-1) = max(abs(eig(alm.transition)));
    if isfield(plugin,'re_plm') && ~isempty(plugin.re_plm)
        belief_distance(t-1) = norm(plm.transition-plugin.re_plm.transition,'fro');
    end
end
run = struct('native_path',y(:,1:last_period),'learning_state',beliefs, ...
    'diagnostics',{diagnostics(1:max(0,last_period-1))}, ...
    'belief_distance_from_re',belief_distance,'plm_stability_root',plm_roots, ...
    'alm_stability_root',alm_roots,'status',status,'termination',termination, ...
    'invalid',status=="invalid",'explosive',status=="explosive");
end

function validate_explosion_policy(policy)
required = {'magnitude_limit','reject_nonfinite','variable_indices'};
assert(isstruct(policy) && isscalar(policy) && ...
    isempty(setxor(fieldnames(policy),required.')), ...
    'Learning:InvalidExplosionPolicy','A complete explosion policy is required.');
assert(isnumeric(policy.magnitude_limit) && isscalar(policy.magnitude_limit) && ...
    isfinite(policy.magnitude_limit) && policy.magnitude_limit>0, ...
    'Learning:InvalidExplosionPolicy','magnitude_limit must be positive and finite.');
assert(islogical(policy.reject_nonfinite) && isscalar(policy.reject_nonfinite), ...
    'Learning:InvalidExplosionPolicy','reject_nonfinite must be logical.');
assert(isnumeric(policy.variable_indices) && isvector(policy.variable_indices) && ...
    ~isempty(policy.variable_indices), ...
    'Learning:InvalidExplosionPolicy','variable_indices must be a nonempty vector.');
end

function value = empty_termination()
value = struct('period',NaN,'variable_index',NaN,'value',NaN, ...
    'criterion',"",'policy',struct());
end

function value = make_termination(period,variable_index,trigger_value,criterion,policy)
value = struct('period',period,'variable_index',variable_index,'value',trigger_value, ...
    'criterion',criterion,'policy',policy);
end
