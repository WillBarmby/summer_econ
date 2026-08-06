function counts = artifact_status_counts(artifact)
%% ARTIFACT_STATUS_COUNTS Count explicit runtime outcomes.

validate_artifact(artifact);
if isfield(artifact,'status_counts')
    counts = artifact.status_counts;
elseif isfield(artifact,'simulation_result')
    status = artifact.simulation_result.status;
    counts = struct('completed',sum(status=="completed"), ...
        'explosive',sum(status=="explosive"), ...
        'invalid',sum(status=="invalid"));
else
    error('AdaptiveLearning:UnsupportedArtifact', ...
        'Artifact has no statuses to count.');
end
end
