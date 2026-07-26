function matrices = unpack_dynare_jacobian(jacobian,dynare_model)
%% UNPACK_DYNARE_JACOBIAN Split a Dynare 7.1 dense dynamic Jacobian.
% Dynare 7.1 orders columns as [all lags, all current values, all leads,
% stochastic exogenous variables]. This helper is retained in the canonical
% model engine for the future nonlinear balanced-growth NK loader.
% Each block therefore supplies the Dlag, D0, Dlead, and Dshock matrices in
% the same structural residual convention used by the explicit-linear loader.

n = dynare_model.endo_nbr;
q = dynare_model.exo_nbr;
assert(dynare_model.exo_det_nbr==0, ...
    'EPResearch:DeterministicExogenous', ...
    'Deterministic exogenous variables are not supported.');
assert(isequal(size(jacobian),[dynare_model.eq_nbr,3*n+q]), ...
    'EPResearch:JacobianLayout','Unexpected Dynare Jacobian dimensions.');
assert(isequal(size(dynare_model.lead_lag_incidence),[3 n]), ...
    'EPResearch:TimingLayout','Only one lag and one lead are supported.');
phase = cell(3,1);
for p = 1:3
    phase{p} = full(jacobian(:,(p-1)*n+(1:n)));
    inactive = dynare_model.lead_lag_incidence(p,:)==0;
    assert(all(abs(phase{p}(:,inactive))<1e-12,'all'), ...
        'EPResearch:InactiveDerivative', ...
        'Dynare returned a derivative for an inactive timing entry.');
end
matrices = struct('lag',phase{1},'current',phase{2}, ...
    'lead',phase{3},'shock',full(jacobian(:,3*n+(1:q))));
end
