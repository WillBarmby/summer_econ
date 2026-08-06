function report = report_artifact(artifact,specification)
%% REPORT_ARTIFACT Transform native artifact paths into named series.

validate_artifact_shape(artifact);
[source_values,source] = select_source(artifact,specification);
series = validate_reporting_specification( ...
    specification,artifact.model.variable_names);
if size(source_values,1)~=numel(artifact.model.variable_names)
    invalid('Artifact source rows do not match model variable names.');
end

values = zeros(numel(series),size(source_values,2));
series_names = strings(numel(series),1);
for j = 1:numel(series)
    series_names(j) = string(series(j).name);
    variable_index = name_index( ...
        artifact.model.variable_names,series(j).variable);
    value = source_values(variable_index,:);
    cumulative = series(j).cumulative_variables;
    for k = 1:numel(cumulative)
        index = name_index(artifact.model.variable_names,cumulative{k});
        value = value+cumsum(source_values(index,:),2);
    end
    values(j,:) = series(j).scale*value;
end

report = struct( ...
    'source',source, ...
    'series_names',series_names, ...
    'horizons',0:size(values,2)-1, ...
    'values',values, ...
    'title',string(specification.title), ...
    'x_label',string(specification.x_label), ...
    'y_label',string(specification.y_label));
end

function validate_artifact_shape(artifact)
required = {'schema_version','model','learning_specification', ...
    'experiment_specification','simulation_result'};
if ~isstruct(artifact) || ~isscalar(artifact) || ...
        ~all(isfield(artifact,required)) || ...
        ~isstruct(artifact.model) || ...
        ~isfield(artifact.model,'variable_names')
    invalid('Input does not match the artifact contract.');
end
end

function [values,source] = select_source(artifact,specification)
if ~isstruct(specification) || ~isscalar(specification) || ...
        ~isfield(specification,'source')
    invalid('Reporting specification must select a source.');
end
source = text_scalar(specification.source);
switch source
    case "path"
        if ~isfield(artifact.simulation_result,'path')
            invalid('Artifact does not contain a single-run path.');
        end
        values = artifact.simulation_result.path;
    case "irf"
        if ~isfield(artifact.simulation_result,'irf')
            invalid('Artifact does not contain a paired IRF.');
        end
        values = artifact.simulation_result.irf;
    otherwise
        invalid('Reporting source must be "path" or "irf".');
end
if ~isnumeric(values) || ~isreal(values) || ~ismatrix(values)
    invalid('Selected artifact source must be a real numeric matrix.');
end
end

function series = validate_reporting_specification(specification,variable_names)
required = {'series';'source';'title';'x_label';'y_label'};
if ~isequal(sort(fieldnames(specification)),required)
    invalid('Reporting specification fields do not match the contract.');
end
text_scalar(specification.title);
text_scalar(specification.x_label);
text_scalar(specification.y_label);
series = specification.series;
series_fields = {'cumulative_variables';'name';'scale';'variable'};
if ~isstruct(series) || isempty(series) || ~isvector(series)
    invalid('Reporting series must be a nonempty struct array.');
end
names = strings(numel(series),1);
for j = 1:numel(series)
    if ~isequal(sort(fieldnames(series(j))),series_fields)
        invalid('Reporting series fields do not match the contract.');
    end
    names(j) = text_scalar(series(j).name);
    name_index(variable_names,series(j).variable);
    cumulative = series(j).cumulative_variables;
    if ~iscell(cumulative) || (~isempty(cumulative) && ~isvector(cumulative))
        invalid('Cumulative variables must be a cell list of names.');
    end
    for k = 1:numel(cumulative)
        name_index(variable_names,cumulative{k});
    end
    if ~isnumeric(series(j).scale) || ~isreal(series(j).scale) || ...
            ~isscalar(series(j).scale) || ~isfinite(series(j).scale)
        invalid('Reporting series scale must be a finite real scalar.');
    end
end
if any(strlength(names)==0) || numel(unique(names))~=numel(names)
    invalid('Reported series names must be unique and nonempty.');
end
end

function index = name_index(names,requested)
requested = text_scalar(requested);
[found,index] = ismember(requested,string(names));
if ~found
    invalid('Unknown reported variable "%s".',requested);
end
end

function value = text_scalar(input)
if ischar(input) && isrow(input)
    value = string(input);
elseif isstring(input) && isscalar(input)
    value = input;
else
    invalid('Expected a reporting text scalar.');
end
end

function invalid(message,varargin)
error('AdaptiveLearning:InvalidReportingSpecification',message,varargin{:});
end
