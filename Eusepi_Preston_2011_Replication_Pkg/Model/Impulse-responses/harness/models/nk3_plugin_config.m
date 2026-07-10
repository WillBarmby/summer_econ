function config = nk3_plugin_config()
%% NK3_PLUGIN_CONFIG Explicit EE/learning metadata for the NK example.

config.name = 'NK3 EE learning';
config.expectations = struct( ...
    'target',{'output_gap','inflation'}, ...
    'horizon',{1,1},'discount',{1,1});
config.learned_variables = {'output_gap','inflation','policy_rate','natural_rate','cost_push'};
config.regressors = {'constant','output_gap_lag','inflation_lag','policy_rate_lag', ...
    'natural_rate_lag','cost_push_lag'};
config.observables = struct('output','output_gap','inflation','inflation', ...
    'policy_rate','policy_rate');
config.formulation = 'EE';
end
