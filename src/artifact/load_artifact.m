function artifact = load_artifact(file)
%% LOAD_ARTIFACT Safely load and validate one canonical schema-3 MAT artifact.

[mat_file,json_file]=resolve_paths(file);
if ~isfile(mat_file), error('AdaptiveLearning:InvalidArtifactFile','Artifact MAT file does not exist.'); end
if isfile(json_file)
    try, metadata=jsondecode(fileread(json_file));
    catch, error('AdaptiveLearning:ArtifactIntegrityFailure','JSON sidecar is malformed.'); end
    if ~isfield(metadata,'mat_sha256')|| ...
            string(metadata.mat_sha256)~=artifact_file_sha256(mat_file)
        error('AdaptiveLearning:ArtifactIntegrityFailure','Artifact checksum does not match sidecar.');
    end
end
try, inventory=whos('-file',mat_file);
catch, error('AdaptiveLearning:InvalidArtifactFile','MAT file cannot be inspected.'); end
if numel(inventory)~=1||~strcmp(inventory.name,'artifact')||~strcmp(inventory.class,'struct')
    error('AdaptiveLearning:InvalidArtifactFile', ...
        'MAT file must contain exactly one struct named artifact.');
end
loaded=load(mat_file,'artifact'); artifact=loaded.artifact;
if ~isstruct(artifact)||~isscalar(artifact)
    error('AdaptiveLearning:InvalidArtifactFile','Artifact value must be a scalar struct.');
end
validate_artifact(artifact);
if isfile(json_file)&&(string(metadata.schema_version)~=artifact.schema_version|| ...
        string(metadata.kind)~=artifact.kind)
    error('AdaptiveLearning:ArtifactIntegrityFailure','Sidecar metadata disagrees with MAT artifact.');
end
end
function [mat_file,json_file]=resolve_paths(file)
file=char(string(file)); [folder,name,extension]=fileparts(file);
if isempty(extension), extension='.mat'; end
if ~strcmpi(extension,'.mat')||isempty(name)
    error('AdaptiveLearning:InvalidArtifactFile','Artifact path must end in .mat.');
end
mat_file=fullfile(folder,[name '.mat']); json_file=fullfile(folder,[name '.json']);
end
