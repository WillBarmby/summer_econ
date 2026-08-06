function components = run_dynare_linear(source,options)
%% RUN_DYNARE_LINEAR Extract structural matrices through the Dynare backend.

components = run_dynare_model(source,options.parameter_overrides, ...
    @extract_linear_components);
end
