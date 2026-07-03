function dims = model_dimensions()
%% MODEL_DIMENSIONS Return dimensions for the impulse-response model system.

dims = struct();
dims.n_var = 13; % total number of variables
dims.n_exog_vars = 1; % number of exogenous variables
dims.n_shocks = 1; %i.i.d. shocks
dims.forecasting_horizon = 1; %% forecasting horizon (finite)

end
