function paths = save_artifact(file,artifact,varargin)
%% SAVE_ARTIFACT Atomically write canonical MAT data and JSON metadata.

parser=inputParser; addParameter(parser,'Overwrite',false,@(x)islogical(x)&&isscalar(x));
parse(parser,varargin{:}); overwrite=parser.Results.Overwrite;
[mat_file,json_file]=resolve_paths(file);
validate_artifact(artifact);
if ~overwrite&&(isfile(mat_file)||isfile(json_file))
    error('AdaptiveLearning:InvalidArtifactFile','Artifact output already exists.');
end
folder=fileparts(mat_file); if isempty(folder), folder=pwd; end
if ~isfolder(folder), mkdir(folder); end
temp_mat=[tempname(folder) '.mat']; temp_json=[tempname(folder) '.json'];
cleanup=onCleanup(@() remove_temps(temp_mat,temp_json)); %#ok<NASGU>
save(temp_mat,'artifact','-v7.3');
metadata=sidecar_metadata(artifact,mat_file,artifact_file_sha256(temp_mat));
write_json(temp_json,metadata);
movefile(temp_mat,mat_file,'f'); movefile(temp_json,json_file,'f');
paths=struct('mat',string(mat_file),'json',string(json_file));
end

function metadata=sidecar_metadata(a,mat_file,checksum)
metadata=struct('schema_version',a.schema_version,'kind',a.kind,'case',a.case, ...
    'model',select_model(a.model),'axes',a.axes,'units',a.units,'timing',a.timing, ...
    'provenance',a.provenance,'dimensions',array_dimensions(a), ...
    'mat_file',string(mat_file),'mat_sha256',checksum);
if isfield(a,'series')
    metadata.series=rmfield(a.series,'transformation');
elseif isfield(a,'irf')&&isstruct(a.irf)&&isfield(a.irf,'series')
    metadata.series=rmfield(a.irf.series,'transformation');
end
if isfield(a,'status'), metadata.status=a.status; end
if isfield(a,'status_counts'), metadata.status_counts=a.status_counts; end
end
function value=select_model(model)
value=struct('name',string(model.name));
if isfield(model,'backend'), value.backend=string(model.backend); end
if isfield(model,'variable_names'), value.variable_names=model.variable_names; end
if isfield(model,'shock_names'), value.shock_names=model.shock_names; end
end
function value=array_dimensions(a)
value=struct(); names={'native_irf','reported_irf','re_native_path', ...
    're_reported_path','native_irfs','learning_draws'};
for j=1:numel(names)
    if isfield(a,names{j}), value.(names{j})=size(a.(names{j})); end
end
end
function write_json(file,value)
handle=fopen(file,'w');
if handle<0, error('AdaptiveLearning:InvalidArtifactFile','Cannot create JSON sidecar.'); end
cleanup=onCleanup(@() fclose(handle)); %#ok<NASGU>
fwrite(handle,jsonencode(value,'PrettyPrint',true),'char');
end
function [mat_file,json_file]=resolve_paths(file)
file=char(string(file)); [folder,name,extension]=fileparts(file);
if isempty(extension), extension='.mat'; end
if ~strcmpi(extension,'.mat')||isempty(name)
    error('AdaptiveLearning:InvalidArtifactFile','Artifact path must end in .mat.');
end
mat_file=fullfile(folder,[name '.mat']); json_file=fullfile(folder,[name '.json']);
end
function remove_temps(varargin)
for j=1:nargin, if isfile(varargin{j}), delete(varargin{j}); end, end
end
