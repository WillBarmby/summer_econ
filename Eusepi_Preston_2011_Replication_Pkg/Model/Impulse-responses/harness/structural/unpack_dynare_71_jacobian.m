function matrices = unpack_dynare_71_jacobian(jacobian,M)
%% UNPACK_DYNARE_71_JACOBIAN Convert Dynare's dense dynamic Jacobian.
%
% Dynare 7.1 generates columns in the order
%   [all y(-1), all y, all y(+1), stochastic exogenous variables].
% lead_lag_incidence identifies which endogenous columns are active. Keeping
% the inactive columns in the generated Jacobian makes each phase n-by-n and
% lets the learning harness use a stable variable ordering.

n=M.endo_nbr;
q=M.exo_nbr;
assert(M.exo_det_nbr==0,'DynareFirstOrder:DeterministicExogenous', ...
    'Deterministic exogenous variables are not supported.');
assert(isequal(size(jacobian),[M.eq_nbr,3*n+q]), ...
    'DynareFirstOrder:JacobianLayout', ...
    'Expected a %d-by-%d Dynare 7.1 dynamic Jacobian.',M.eq_nbr,3*n+q);
assert(isequal(size(M.lead_lag_incidence),[3,n]), ...
    'DynareFirstOrder:TimingLayout', ...
    'Only models with at most one lag and one lead are supported.');

phase=cell(3,1);
for p=1:3
    columns=(p-1)*n+(1:n);
    phase{p}=full(jacobian(:,columns));
    inactive=M.lead_lag_incidence(p,:)==0;
    assert(all(abs(phase{p}(:,inactive))<1e-12,'all'), ...
        'DynareFirstOrder:InactiveDerivative', ...
        'Dynare returned a derivative for an inactive phase-variable pair.');
end

matrices=struct('lag',phase{1},'current',phase{2}, ...
    'lead',phase{3},'shock',full(jacobian(:,3*n+(1:q))));
end
