function params = parse_model_parameters(param)
%% PARSE_MODEL_PARAMETERS Name the legacy parameter vector entries.

params = struct();
params.infinite_horizon = param(1); %% if set == 1 chooses inf. horizon approach
params.external_effects = param(2); %% external effects
params.sigma = param(3); %% parameter in the utility function
params.simple_rbc = param(4); %% simple RBC specification flag
params.inverse_labor_elasticity = param(5); %% inv. of elasticity of labor supply

end
