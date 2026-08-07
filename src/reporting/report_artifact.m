function report = report_artifact(artifact,specification)
%% REPORT_ARTIFACT Transform one native artifact source into described series.

validate_artifact(artifact);
[native,source] = select_source(artifact,specification);
[values,series] = apply_reporting_specification( ...
    native,artifact.model.variable_names,specification);
report = struct('source',source,'series',series, ...
    'series_ids',string({series.id}).','series_labels',string({series.label}).', ...
    'units',string({series.unit}).','horizons',0:size(values,2)-1, ...
    'values',values,'title',string(specification.title), ...
    'x_label',string(specification.x_label),'y_label',string(specification.y_label));
end

function [values,source] = select_source(artifact,specification)
source=string(specification.source);
if source=="path" && isfield(artifact,'simulation_result') && ...
        isfield(artifact.simulation_result,'path')
    values=artifact.simulation_result.path;
elseif source=="irf" && isfield(artifact,'native_irf')
    values=artifact.native_irf;
elseif source=="irf" && isfield(artifact,'simulation_result') && ...
        isfield(artifact.simulation_result,'irf')
    values=artifact.simulation_result.irf;
else
    error('AdaptiveLearning:InvalidReportingSpecification', ...
        'Artifact does not expose requested source "%s".',source);
end
end
