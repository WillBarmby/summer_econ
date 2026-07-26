function alm = plm_to_alm_one_step(model,plm)
%% PLM_TO_ALM_ONE_STEP Substitute one-step subjective forecasts into equations.
% Structural residual:
%   D0*y_t+Dlag*y_(t-1)+Dlead*E_t[y_(t+1)]+Dshock*eps_t=0.
%
% Agents perceive the affine law of motion (PLM)
%   y_t = a + B*y_(t-1) + C*eps_t,
% so their one-step forecast is
%   E_t[y_(t+1)] = a + B*y_t.
% Substitution into the structural residual collects the endogenous current
% variables on the left:
%   (D0+Dlead*B)*y_t
%       = -Dlead*a-Dlag*y_(t-1)-Dshock*eps_t.
% Solving this system gives the actual law of motion (ALM) implied by the
% agents' beliefs. Notice that the perceived shock loading C is irrelevant
% to a one-step conditional mean because future innovations have mean zero.

n = numel(model.variable_names);
assert(isequal(size(plm.transition),[n n]), ...
    'EPResearch:InvalidPlm','PLM transition must be n-by-n.');
lhs = model.current+model.lead*plm.transition;
assert(rcond(lhs)>1e-12,'EPResearch:SingularAlm', ...
    'Belief-dependent EE system is singular.');
alm = struct('intercept',-(lhs\(model.lead*plm.intercept(:))), ...
    'transition',-(lhs\model.lag),'shock_impact',-(lhs\model.shock));
alm.stability_root = max(abs(eig(alm.transition)));
end
