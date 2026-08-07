function [values,series] = apply_reporting_specification(native,variable_names,specification)
%% APPLY_REPORTING_SPECIFICATION Transform native rows into described series.

series = validate_specification(specification,variable_names);
values = zeros(numel(series),size(native,2));
for j=1:numel(series)
    transform = series(j).transformation;
    index = name_index(variable_names,transform.variable);
    value = native(index,:);
    if string(transform.kind)=="add_cumulative"
        for k=1:numel(transform.cumulative_variables)
            c = name_index(variable_names,transform.cumulative_variables{k});
            value = value+cumsum(native(c,:),2);
        end
    end
    values(j,:) = transform.scale*value;
end
end

function series = validate_specification(specification,variable_names)
required = {'series';'source';'title';'x_label';'y_label'};
if ~isstruct(specification)||~isscalar(specification)|| ...
        ~isequal(sort(fieldnames(specification)),required)
    invalid('Reporting specification fields do not match the contract.');
end
series=specification.series;
fields={'id';'label';'transformation';'unit'};
if ~isstruct(series)||isempty(series)||~isvector(series)
    invalid('Reporting series must be a nonempty descriptor array.');
end
ids=strings(numel(series),1);
allowed_units=["model_units" "percent_deviation" "percentage_points"];
for j=1:numel(series)
    if ~isequal(sort(fieldnames(series(j))),fields), invalid('Malformed series descriptor.'); end
    ids(j)=text_scalar(series(j).id); text_scalar(series(j).label);
    if ~any(text_scalar(series(j).unit)==allowed_units), invalid('Unsupported series unit.'); end
    t=series(j).transformation;
    kind=text_scalar(t.kind);
    if kind=="native"
        if ~isequal(sort(fieldnames(t)),{'kind';'scale';'variable'})
            invalid('Malformed native transformation.');
        end
    elseif kind=="add_cumulative"
        if ~isequal(sort(fieldnames(t)), ...
                {'cumulative_variables';'kind';'scale';'variable'}) || ...
                ~iscell(t.cumulative_variables)
            invalid('Malformed cumulative transformation.');
        end
        for k=1:numel(t.cumulative_variables)
            name_index(variable_names,t.cumulative_variables{k});
        end
    else
        invalid('Unsupported series transformation.');
    end
    name_index(variable_names,t.variable);
    if ~isnumeric(t.scale)||~isreal(t.scale)||~isscalar(t.scale)||~isfinite(t.scale)
        invalid('Transformation scale must be finite.');
    end
end
if any(strlength(ids)==0)||numel(unique(ids))~=numel(ids)
    invalid('Series IDs must be unique and nonempty.');
end
end
function index=name_index(names,requested)
[found,index]=ismember(text_scalar(requested),string(names));
if ~found, invalid('Unknown reported variable "%s".',string(requested)); end
end
function value=text_scalar(input)
if ischar(input)&&isrow(input), value=string(input);
elseif isstring(input)&&isscalar(input), value=input;
else, invalid('Expected a text scalar.'); end
end
function invalid(message,varargin)
error('AdaptiveLearning:InvalidReportingSpecification',message,varargin{:});
end
