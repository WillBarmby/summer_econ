function validate_artifact(artifact)
%% VALIDATE_ARTIFACT Enforce inspectable, nonexecutable result values.

required = {'schema_version','kind','case','model','axes','units', ...
    'timing','provenance'};
if ~isstruct(artifact) || ~isscalar(artifact) || ~all(isfield(artifact,required))
    invalid('Artifact lacks common metadata.');
end
allowed = ["single_run" "training_irf" "case_collection" "comparison"];
if ~any(string(artifact.kind)==allowed)
    invalid('Artifact kind is not recognized.');
end
if contains_function_handle(artifact)
    invalid('Artifacts cannot contain callbacks or closures.');
end
if isfield(artifact.model,'current') || isfield(artifact.model,'lag') || ...
        isfield(artifact.model,'lead') || isfield(artifact.model,'shock')
    invalid('Artifacts cannot contain structural matrices.');
end
if ~isstruct(artifact.axes) || ~isstruct(artifact.units) || ...
        ~isstruct(artifact.timing) || ~isstruct(artifact.provenance)
    invalid('Artifact metadata must be structured.');
end
if artifact.kind=="comparison"
    if ~isfield(artifact,'cases') || ~iscell(artifact.cases) || ...
            isempty(artifact.cases)
        invalid('Comparison artifacts require case artifacts.');
    end
    cellfun(@validate_artifact,artifact.cases);
end
end

function result = contains_function_handle(value)
if isa(value,'function_handle')
    result = true;
elseif isstruct(value)
    result = any(arrayfun(@(j) any(cellfun(@contains_function_handle, ...
        struct2cell(value(j)))),1:numel(value)));
elseif iscell(value)
    result = any(cellfun(@contains_function_handle,value));
else
    result = false;
end
end

function invalid(message)
error('AdaptiveLearning:InvalidArtifact',message);
end
