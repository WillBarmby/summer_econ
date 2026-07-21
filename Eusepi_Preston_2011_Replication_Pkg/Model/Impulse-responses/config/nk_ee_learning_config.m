function config = nk_ee_learning_config(gain)
%% NK_EE_LEARNING_CONFIG Define the primary NK Euler-equation experiment.
% The comparison calibration makes technology i.i.d. Agents observe the
% current innovation when making current decisions, but do not include it
% in their perceived forecasting model. They estimate the minimum-state-
% variable law using a constant and lagged aggregate capital.

if nargin~=1 || ~isnumeric(gain) || ~isscalar(gain) || ...
        ~isfinite(gain) || gain<=0 || gain>1
    error('NKEE:InvalidGain','gain must be a finite scalar in (0,1].');
end
config=struct();
config.variant="iid_comparison";
config.learned_outcomes={'rk','consumption','inflation','capital'};
config.regressors={'constant','capital_lag'};
config.state_variable='capital';
config.observed_but_excluded={'eps_technology'};
config.gain=struct('type','constant','value',gain,'offset',500);
config.initialization="dynare_re";
config.update_timing="decide_then_update";
config.projection=struct('outcome','capital','absolute_limit',0.99, ...
    'action',"reject_update");
end
