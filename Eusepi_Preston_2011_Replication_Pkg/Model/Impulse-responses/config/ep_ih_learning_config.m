function config = ep_ih_learning_config()
%% EP_IH_LEARNING_CONFIG Eusepi-Preston (2011) benchmark belief specification.
%
% Paper Section II: agents forecast prices with a constant and lagged
% aggregate capital; the technology innovation is observed but excluded.
% Online Appendix, Consumption decision rule: wage and capital-return present
% values are derived from the forecasting model, not estimated separately.

config = struct();
config.formulation = "infinite_horizon";
% Paper equations (8)-(10): agents estimate only the capital return,
% efficiency wage, and next-period capital equations.
config.learned_outcomes = {'rk','wage','capital'};
config.regressors = {'constant','capital_lag'};
config.state_variable = 'capital';
config.observed_but_excluded = {'eps_x'};
config.forecast_targets = {'rk','wage'};
config.present_value_variables = {'rk_sum','w_sum'};
config.present_value_equations = {'capital_pv','wage_pv'};
config.decision_equation = 'ih_consumption';
config.decision_forecast_targets = {'gamma_x','rk','wage'};
config.gain = struct('type','constant','value',0.002,'offset',500);
config.feedback = true;
config.update_timing = "decide_then_update";
config.initialization = "dynare_re";
config.rcond_tolerance = 1.0856345e-10;
config.projection = struct('outcome','capital','regressor','capital_lag', ...
    'absolute_limit',0.99,'action',"reject_update");
end
