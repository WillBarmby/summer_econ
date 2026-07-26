function covariance = stationary_covariance(transition,shock,shock_variance)
%% STATIONARY_COVARIANCE Solve P=A*P*A'+B*Sigma*B' by iteration.
% This replaces the legacy VCV_Model/doublej dependency with the defining
% discrete Lyapunov recursion. The RE transition must be stable.
% Economically, P is the unconditional covariance of y_t under
%   y_t=A*y_(t-1)+B*eps_t,  Var(eps_t)=Sigma.
% It initializes the RLS regressor moment matrix consistently with the RE
% data-generating process used to initialize agents' beliefs.

n = size(transition,1);
assert(isequal(size(transition),[n n]), ...
    'EPResearch:InvalidTransition','Transition must be square.');
assert(size(shock,1)==n,'EPResearch:InvalidShock', ...
    'Shock impact has the wrong row dimension.');
q = size(shock,2);
if isscalar(shock_variance)
    shock_variance = shock_variance*eye(q);
end
assert(isequal(size(shock_variance),[q q]) && ...
    all(isfinite(shock_variance),'all'), ...
    'EPResearch:InvalidShockVariance','Shock variance has wrong dimensions.');
assert(max(abs(eig(transition)))<1,'EPResearch:UnstableTransition', ...
    'Stationary covariance requires a stable transition.');

innovation = shock*shock_variance*shock';
covariance = zeros(n);
% Starting from zero, repeated substitution adds successively older shock
% contributions: B*Sigma*B' + A*B*Sigma*B'*A' + ... . Stability guarantees
% convergence to the unique stationary covariance.
for iteration = 1:100000
    updated = transition*covariance*transition'+innovation;
    if norm(updated-covariance,'fro')<=1e-13*max(1,norm(updated,'fro'))
        covariance = (updated+updated')/2;
        return
    end
    covariance = updated;
end
error('EPResearch:CovarianceDidNotConverge', ...
    'Stationary covariance iteration did not converge.');
end
