function validate_artifact(a)
%% VALIDATE_ARTIFACT Validate exact schema-3 contracts by artifact kind.
if ~isstruct(a)||~isscalar(a), invalid('Artifact must be a scalar struct.'); end
if ~isfield(a,'schema_version')||string(a.schema_version)~="3.0"
    error('AdaptiveLearning:UnsupportedArtifactSchema','Only schema 3.0 is supported.');
end
if contains_executable(a), invalid('Artifacts cannot contain executable values or objects.'); end
if ~all(isfield(a,{'kind','case','model','axes','units','timing','provenance'}))
    invalid('Artifact lacks common metadata.');
end
common(a);
switch string(a.kind)
    case "single_run", single(a);
    case "training", training(a);
    case "irf", irf(a);
    case "training_irf", training_irf(a);
    case "case_collection", collection(a);
    case "comparison", comparison(a);
    otherwise, invalid('Unknown artifact kind.');
end
end
function common(a)
if ~isstruct(a.case)||~all(isfield(a.case,{'id','label'}))||strlength(string(a.case.id))==0|| ...
        ~isstruct(a.model)||~isstruct(a.axes)||~isstruct(a.units)|| ...
        ~isstruct(a.timing)||~isstruct(a.provenance)
    invalid('Malformed common artifact metadata.');
end
if any(isfield(a.model,{'current','lag','lead','shock','re','dynare'}))
    invalid('Structural matrices and backend state cannot enter artifacts.');
end
end
function single(a)
exact(a,{'schema_version','kind','case','model','learning_specification', ...
    'experiment_specification','simulation_result','axes','units','timing','provenance'});
if ~isfield(a.simulation_result,'path'), invalid('Malformed single-run result.'); end
end
function training(a)
exact(a,{'schema_version','kind','case','model','learning_specification', ...
    'reporting_specification','training_design','simulation_result','terminal', ...
    'status','termination','axes','units','timing','provenance'});
model_names(a.model); status(a.status,a.termination);
n=numel(a.model.variable_names); q=numel(a.model.shock_names); d=a.training_design;
if ~isfield(d,'shocks')||~isequal(size(d.shocks),[q d.periods])|| ...
        ~isequal(size(a.simulation_result.path),[n d.periods+1])|| ...
        ~isequal(size(a.terminal.values),[n 1])||~isstruct(a.terminal.beliefs)|| ...
        ~isfield(a.provenance,'case_fingerprint')
    invalid('Training dimensions or terminal handoff are inconsistent.');
end
named_shocks(d.shocks,a.model.shock_names,d.shock_name);
end
function irf(a)
exact(a,{'schema_version','kind','case','model','learning_specification', ...
    'reporting_specification','training_reference','irf_design','baseline','shocked', ...
    'primitive_irf','native_irf','reported_irf','re_native_path','re_reported_path', ...
    'series','status','termination','axes','units','timing','provenance'});
model_names(a.model); status(a.status,a.termination);
n=numel(a.model.variable_names); q=numel(a.model.shock_names); h=a.irf_design.periods; s=numel(a.series);
if ~isequal(size(a.primitive_irf),[n h+1])||~isequal(size(a.native_irf),[n h])|| ...
        ~isequal(size(a.reported_irf),[s h])||~isequal(size(a.re_native_path),[n h])|| ...
        ~isequal(size(a.re_reported_path),[s h])|| ...
        ~isequal(size(a.irf_design.baseline_shocks),[q h])|| ...
        ~isequal(size(a.irf_design.shocked_shocks),[q h])
    invalid('IRF arrays do not match declared dimensions.');
end
series(a.series); named_shocks(a.irf_design.baseline_shocks, ...
    a.model.shock_names,a.irf_design.shock_name);
end
function training_irf(a)
exact(a,{'schema_version','kind','case','model','learning_specification', ...
    'reporting_specification','study_design','training','irf','status','termination', ...
    'axes','units','timing','provenance'});
training(a.training); status(a.status,a.termination);
if ~isempty(a.irf)
    irf(a.irf);
    if a.training.provenance.case_fingerprint~=a.irf.training_reference.case_fingerprint
        invalid('Training and IRF fingerprints differ.');
    end
end
end
function collection(a)
exact(a,{'schema_version','kind','case','model','learning_specification', ...
    'reporting_specification','study_design','series','re_native_path', ...
    're_reported_path','native_irfs','learning_draws','terminal_training_coefficients', ...
    'terminal_training_moments','training_projection_events','statuses','terminations', ...
    'status_counts','summary','axes','units','timing','provenance'});
model_names(a.model); series(a.series);
d=numel(a.statuses); n=numel(a.model.variable_names); s=numel(a.series); h=numel(a.timing.horizons);
if ~isequal(size(a.native_irfs),[d n h])||~isequal(size(a.learning_draws),[d s h])|| ...
        ~isequal(size(a.re_native_path),[n h])||~isequal(size(a.re_reported_path),[s h])|| ...
        numel(a.terminations)~=d||numel(a.training_projection_events)~=d|| ...
        a.status_counts.completed+a.status_counts.explosive+a.status_counts.invalid~=d
    invalid('Collection dimensions or status counts are inconsistent.');
end
end
function comparison(a)
exact(a,{'schema_version','kind','case','model','study_design','cases','status', ...
    'termination','axes','units','timing','provenance'});
status(a.status,a.termination);
if ~iscell(a.cases)||isempty(a.cases), invalid('Comparison requires cases.'); end
for j=1:numel(a.cases)
    validate_artifact(a.cases{j});
    if a.cases{j}.kind~="case_collection"|| ...
            a.cases{j}.provenance.innovation_fingerprint~=a.provenance.innovation_fingerprint
        invalid('Comparison innovation fingerprints differ.');
    end
end
end
function series(value)
if isempty(value)||~all(isfield(value,{'id','label','unit','transformation'})), invalid('Malformed series.'); end
ids=string({value.id}); units=string({value.unit});
if numel(unique(ids))~=numel(ids)||any(strlength(ids)==0)|| ...
        any(~ismember(units,["model_units" "percent_deviation" "percentage_points"]))
    invalid('Series IDs or units are invalid.');
end
end
function named_shocks(shocks,names,selected)
[found,index]=ismember(string(selected),string(names));
if ~found, invalid('Selected shock is absent from model metadata.'); end
if any(shocks(setdiff(1:numel(names),index),:)~=0,'all'), invalid('Unselected shocks must be zero.'); end
end
function status(value,termination)
value=string(value);
if ~any(value==["completed" "invalid" "explosive"]), invalid('Unknown status.'); end
if value=="completed"&&~isempty(fieldnames(termination)), invalid('Completed status has termination data.'); end
if value~="completed"&&isempty(fieldnames(termination)), invalid('Failed status lacks termination data.'); end
end
function model_names(model)
if ~all(isfield(model,{'name','variable_names','shock_names'}))|| ...
        numel(unique(string(model.variable_names)))~=numel(model.variable_names)|| ...
        numel(unique(string(model.shock_names)))~=numel(model.shock_names)
    invalid('Model names are missing or duplicated.');
end
end
function exact(value,fields)
if ~isequal(sort(fieldnames(value)),sort(fields(:))), invalid('Fields do not match artifact kind.'); end
end
function result=contains_executable(value)
if isa(value,'function_handle')||(isobject(value)&&~isstring(value)), result=true;
elseif isstruct(value), result=any(arrayfun(@(j) any(cellfun(@contains_executable,struct2cell(value(j)))),1:numel(value)));
elseif iscell(value), result=any(cellfun(@contains_executable,value)); else, result=false; end
end
function invalid(message)
error('AdaptiveLearning:InvalidArtifact',message);
end
