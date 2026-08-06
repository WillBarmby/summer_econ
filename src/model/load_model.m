function structural_model = load_model(model_file,model_options)
%% LOAD_MODEL Load a model file into the public structural-model contract.
% The public loader orchestrates the handoff. Dynare setup, generated files,
% and residual-matrix extraction live in private helpers so this function
% states the intended data flow without exposing Dynare's data store.

if nargin<2
    model_options = struct();
end
options = validate_load_options(model_options);
source = validate_model_source(model_file,options);

components = run_dynare_linear(source,options);
structural_model = assemble_structural_model(components,source,options);

% This is the new boundary check. The current validator is intentionally
% still legacy and will be migrated against the red contract tests.
validate_structural_model(structural_model);
end
