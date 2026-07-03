function invalid_params = validate_model_parameters(params)
%% VALIDATE_MODEL_PARAMETERS Check calibrated/estimated parameter bounds.

invalid_params = params.external_effects > 1 || ...
    params.sigma > 2.8 || ...
    params.sigma < 1;

end
