function options = nk_model_options()
%% NK_MODEL_OPTIONS Canonical nonlinear-loader test configuration.

options = struct('kind',"nonlinear", ...
    'parameter_overrides',struct(), ...
    'deviation_scales',struct('gamma_x',0.01));
end
