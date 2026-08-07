function components = run_dynare_nonlinear(source,options)
%% RUN_DYNARE_NONLINEAR Extract a scaled first-order structural system.

components = run_dynare_model(source,options.parameter_overrides, ...
    @(context) extract_nonlinear_components(context,options));
end
