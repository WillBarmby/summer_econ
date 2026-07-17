function config = ep_ee_learning_config(variant,gain)
%% EP_EE_LEARNING_CONFIG Distinguish paper EE from archived-code EE.
% paper: equation (17) directly forecasts consumption; rk and capital are
% the other minimum-state-variable forecasting equations.
% archive: the released code updates its first seven legacy rows and never
% replaces the consumption PLM. In the reduced Dynare model, bond is absent
% and the six economically shared rows reproduce that archived behavior.

if nargin~=2
    error('EPEE:RequiredVariant','Supply variant (paper or archive) and gain.');
end
config=struct();
config.variant=string(variant);
switch config.variant
    case "paper"
        config.learned_outcomes={'rk','consumption','capital'};
    case "archive"
        config.learned_outcomes={'rk','wage','output','hours','caput','capital'};
    otherwise
        error('EPEE:InvalidVariant','variant must be paper or archive.');
end
config.regressors={'constant','capital_lag'};
config.state_variable='capital';
config.observed_but_excluded={'eps_x'};
config.gain=struct('type','constant','value',gain,'offset',500);
config.initialization="dynare_re";
config.update_timing="decide_then_update";
config.projection=struct('outcome','capital','absolute_limit',0.99, ...
    'action',"reject_update");
end
