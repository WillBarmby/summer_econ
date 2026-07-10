function solution=solve_plm_fixed_point(model,initial,damping,tolerance,max_iterations)
%% SOLVE_PLM_FIXED_POINT Solve the canonical PLM-to-ALM RE fixed point.

n=numel(model.variable_names);
if nargin<2 || isempty(initial), initial=struct('intercept',zeros(n,1),'transition',zeros(n)); end
if nargin<3, damping=0.01; end
if nargin<4, tolerance=1e-12; end
if nargin<5, max_iterations=200000; end
plm=initial; distance=Inf;
for iteration=1:max_iterations
    alm=plm_to_alm_linear(model,plm);
    next.intercept=plm.intercept+damping*(alm.intercept-plm.intercept);
    next.transition=plm.transition+damping*(alm.transition-plm.transition);
    distance=max([max(abs(next.intercept-plm.intercept)), ...
        max(abs(next.transition-plm.transition),[],'all')]);
    plm=next;
    if distance<tolerance, break; end
end
solution=struct('intercept',plm.intercept,'transition',plm.transition, ...
    'converged',distance<tolerance,'iterations',iteration,'terminal_distance',distance, ...
    'alm',plm_to_alm_linear(model,plm));
end
