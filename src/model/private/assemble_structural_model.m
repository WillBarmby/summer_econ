function structural_model = assemble_structural_model(components,source,options)
%% ASSEMBLE_STRUCTURAL_MODEL Build the only value exported by LOAD_MODEL.
% This assembly step is intentionally boring: it makes the public contract
% visible and prevents Dynare's M_, oo_, and decision-rule data from leaking
% into downstream learning code.

structural_model = components;
structural_model.name = source.name;
structural_model.backend = "dynare-"+options.kind+"-first-order";
structural_model.source = struct( ...
    'file',source.file, ...
    'kind',source.kind, ...
    'parameter_overrides',options.parameter_overrides, ...
    'deviation_scales',options.deviation_scales);
end
