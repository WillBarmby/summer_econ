function specification = nk_ee_specification(gain)
%% NK_EE_SPECIFICATION One-step learning assumptions for the NK model.
% Agents estimate affine forecasting laws using a constant and lagged chosen
% capital. The five learned outcomes cover every endogenous object whose future
% value appears in the capital Euler, bond Euler, or Rotemberg pricing equations,
% plus capital's transition law:
%
%   E_t[rk_(t+1)], E_t[c_(t+1)], E_t[k_(t+1)],
%   E_t[pi_(t+1)], and E_t[y_(t+1)].
%
% Technology growth is observed when realized but omitted from the regression,
% matching the information philosophy of the E&P EE comparison. With rho_x=0,
% agents know that future technology-growth innovations have conditional mean
% zero. The dormant risk-premium innovation is not part of this baseline
% technology-shock experiment.

specification = struct('variant',"nk_one_step", ...
    'learned_outcomes',{{'rk','consumption','capital','inflation','output'}}, ...
    'regressors',{{'constant','capital_lag'}}, ...
    'state_variable','capital','observed_but_excluded',{{'eps_x'}}, ...
    'gain',struct('type','constant','value',gain,'offset',500), ...
    'initialization',"dynare_re",'update_timing',"decide_then_update", ...
    'projection',struct('outcome','capital','absolute_limit',0.99, ...
    'action',"reject_update"));
end
