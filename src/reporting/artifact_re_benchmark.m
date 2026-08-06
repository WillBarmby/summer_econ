function benchmark = artifact_re_benchmark(artifact,space)
%% ARTIFACT_RE_BENCHMARK Select the native or reported RE path.

validate_artifact(artifact);
if nargin<2, space = "reported"; end
switch string(space)
    case "reported"
        benchmark = artifact.re_reported_path;
    case "native"
        benchmark = artifact.re_native_path;
    otherwise
        error('AdaptiveLearning:UnsupportedArtifact', ...
            'RE benchmark space must be native or reported.');
end
end
