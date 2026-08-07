function summary = artifact_summary(artifact)
%% ARTIFACT_SUMMARY Return stored or computed pointwise learning summaries.

validate_artifact(artifact);
if isfield(artifact,'summary')
    summary = artifact.summary;
elseif isfield(artifact,'learning_draws') && isfield(artifact,'re_reported_path')
    probabilities = artifact.study_design.band_probabilities;
    summary = summarize_draws(artifact.learning_draws, ...
        artifact.re_reported_path,probabilities);
else
    error('AdaptiveLearning:UnsupportedArtifact', ...
        'Artifact does not contain a draw summary boundary.');
end
end
