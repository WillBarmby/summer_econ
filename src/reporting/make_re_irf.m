function path = make_re_irf(learning_model,horizon,impulse)
%% MAKE_RE_IRF Simulate the fixed-belief RE response to a structural impulse.
% The RE PLM is passed through the same expectations mapping as learning, so
% the benchmark uses the same structural equations and reporting convention.

alm = learning_model.plm_to_alm(learning_model.re_plm);
n = numel(learning_model.model.variable_names);
path = zeros(n,horizon);
path(:,1) = alm.shock_impact*impulse(:);
for period = 2:horizon
    path(:,period) = alm.transition*path(:,period-1);
end
end
