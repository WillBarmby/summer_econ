function alm = plm_to_alm_linear(model, plm)
%% PLM_TO_ALM_LINEAR Substitute one-step subjective forecasts into a model.
%
% Structural residual:
% D0*y_t + Dlag*y_(t-1) + Dlead*E_t[y_(t+1)] + Dshock*eps_t = 0.

n = numel(model.variable_names);
assert(isequal(size(plm.transition),[n n]));
lhs = model.current+model.lead*plm.transition;
assert(rcond(lhs)>1e-12,'Belief-dependent EE system is singular.');
alm = struct();
alm.intercept = -(lhs\(model.lead*plm.intercept(:)));
alm.transition = -(lhs\model.lag);
alm.shock_impact = -(lhs\model.shock);
alm.stability_root = max(abs(eig(alm.transition)));
end
