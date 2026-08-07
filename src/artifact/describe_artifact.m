function description = describe_artifact(artifact)
%% DESCRIBE_ARTIFACT Return a concise machine-readable schema description.

validate_artifact(artifact);
description = struct('schema_version',artifact.schema_version, ...
    'kind',artifact.kind,'case',artifact.case,'model',artifact.model.name, ...
    'axes',artifact.axes,'units',artifact.units,'timing',artifact.timing, ...
    'provenance',artifact.provenance);
if isfield(artifact,'status')
    description.status = artifact.status;
elseif isfield(artifact,'simulation_result')
    description.status = artifact.simulation_result.status;
elseif isfield(artifact,'status_counts')
    description.status = artifact.status_counts;
elseif artifact.kind=="comparison"
    description.status = cellfun(@(value) value.status_counts, ...
        artifact.cases,'UniformOutput',false);
end
end
