function source = validate_solver_source(structural_model)
%% VALIDATE_SOLVER_SOURCE Recover the reproducible backend input handle.
% Structural matrices do not generally contain enough information to ask
% Dynare for its decision rule. LOAD_MODEL therefore retains only this
% inert source description—not Dynare state—so SOLVE_RE can reproduce the
% solve behind its own boundary.

if ~isfield(structural_model,'source') || ...
        ~isstruct(structural_model.source) || ...
        ~isscalar(structural_model.source)
    error('AdaptiveLearning:MissingSolverSource', ...
        'The structural model has no source metadata for the RE solver.');
end

source = structural_model.source;
required = {'file','kind','parameter_overrides'};
if ~all(isfield(source,required))
    error('AdaptiveLearning:MissingSolverSource', ...
        'The structural model has incomplete source metadata.');
end
if ~(ischar(source.file) || ...
        (isstring(source.file) && isscalar(source.file))) || ...
        ~isfile(source.file)
    error('AdaptiveLearning:MissingSolverSource', ...
        'The structural model source file is unavailable.');
end
if string(source.kind)~="linear"
    error('AdaptiveLearning:UnsupportedModelKind', ...
        'The new RE solver currently supports only linear Dynare models.');
end
if ~isstruct(source.parameter_overrides) || ...
        ~isscalar(source.parameter_overrides)
    error('AdaptiveLearning:MissingSolverSource', ...
        'The structural model has invalid parameter override metadata.');
end

[~,source.name] = fileparts(char(source.file));
source.file = char(source.file);
end
