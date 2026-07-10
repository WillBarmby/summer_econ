function run = simulate_learning_path(plugin, shocks, initial_y, initial_learning)
%% SIMULATE_LEARNING_PATH Generic adaptive-learning simulation.
%
% A plugin supplies beliefs_to_plm, plm_to_alm, regressor, and outcome.

T = size(shocks,2)+1;
n = numel(initial_y);
y = zeros(n,T); y(:,1) = initial_y(:);
beliefs = initial_learning;
diagnostics = repmat(struct(),1,T-1);
belief_distance = NaN(1,T-1);
plm_roots = NaN(1,T-1);
alm_roots = NaN(1,T-1);
invalid = false;
for t = 2:T
    plm = plugin.beliefs_to_plm(beliefs);
    alm = plugin.plm_to_alm(plm);
    y(:,t) = alm.intercept+alm.transition*y(:,t-1)+alm.shock_impact*shocks(:,t-1);
    if any(~isfinite(y(:,t))) || max(abs(y(:,t))) > plugin.explosion_limit
        invalid = true; break
    end
    x = plugin.regressor(y,t);
    target = plugin.outcome(y,t);
    [beliefs,diagnostics(t-1)] = update_rls(beliefs,x,target,plugin.learning);
    if beliefs.invalid
        invalid = true; break
    end
    plm_roots(t-1) = max(abs(eig(plm.transition)));
    alm_roots(t-1) = max(abs(eig(alm.transition)));
    if isfield(plugin,'re_plm') && ~isempty(plugin.re_plm)
        belief_distance(t-1) = norm(plm.transition-plugin.re_plm.transition,'fro');
    end
end
run = struct('native_path',y,'learning_state',beliefs,'diagnostics',{diagnostics}, ...
    'belief_distance_from_re',belief_distance,'plm_stability_root',plm_roots, ...
    'alm_stability_root',alm_roots,'invalid',invalid);
end
