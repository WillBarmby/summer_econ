function artifact = assemble_artifact( ...
    structural_model,learning_specification, ...
    experiment_specification,simulation_result)
%% ASSEMBLE_ARTIFACT Build a nonexecutable reproducibility container.

validate_structural_model(structural_model);
validate_learning_specification(learning_specification);
if contains_function_handle(experiment_specification) || ...
        contains_function_handle(simulation_result)
    invalid('Artifacts cannot contain executable content.');
end
validate_experiment_input(experiment_specification);
validate_simulation_result(simulation_result);

kind = "single_run";
if isfield(simulation_result,'irf')
    kind = "training_irf";
    period_count = size(simulation_result.irf,2)-1;
else
    period_count = size(simulation_result.path,2)-1;
end
metadata = extract_model_metadata(structural_model);
artifact = struct( ...
    'schema_version',"2.0", ...
    'kind',kind, ...
    'case',struct('id',metadata.name,'label',metadata.name), ...
    'model',metadata, ...
    'learning_specification',learning_specification, ...
    'experiment_specification',experiment_specification, ...
    'simulation_result',simulation_result, ...
    'axes',struct('path',{{'native_variable','primitive_time'}}, ...
        'irf',{{'native_variable','primitive_time'}}), ...
    'units',struct('native',"model deviation units",'time',"periods"), ...
    'timing',struct('primitive_path',"[y0,y1,...,yT]", ...
        'periods',0:period_count), ...
    'provenance',struct('generator',"assemble_artifact"));
validate_artifact(artifact);
end

function metadata = extract_model_metadata(model)
metadata = struct( ...
    'name',optional_field(model,'name',""), ...
    'backend',optional_field(model,'backend',""), ...
    'source',optional_field(model,'source',struct()), ...
    'variable_names',{model.variable_names}, ...
    'shock_names',{model.shock_names}, ...
    'equation_names',{model.equation_names}, ...
    'calibration',model.calibration, ...
    'transformation',model.transformation);
if contains_function_handle(metadata)
    invalid('Model metadata cannot contain executable content.');
end
end

function value = optional_field(input,name,default)
if isfield(input,name)
    value = input.(name);
else
    value = default;
end
end

function validate_experiment_input(specification)
if ~isstruct(specification) || ~isscalar(specification)
    invalid('Experiment metadata must be a scalar declarative struct.');
end
if all(isfield(specification,{'training','baseline','shocked'}))
    if ~isequal(sort(fieldnames(specification)), ...
            {'baseline';'shocked';'training'})
        invalid('Paired experiment metadata has unexpected fields.');
    end
    validate_one_experiment(specification.training);
    validate_one_experiment(specification.baseline);
    validate_one_experiment(specification.shocked);
else
    validate_one_experiment(specification);
end
end

function validate_one_experiment(specification)
try
    validate_experiment_specification(specification);
catch exception
    error('AdaptiveLearning:InvalidArtifact', ...
        'Artifact contains an invalid experiment specification: %s', ...
        exception.message);
end
end

function validate_simulation_result(result)
if ~isstruct(result) || ~isscalar(result) || ...
        ~all(isfield(result,{'status','termination'}))
    invalid('Simulation result lacks status or termination information.');
end
single_fields = {'path','belief_history','plm_history','alm_history', ...
    'diagnostics','terminal_beliefs'};
paired_fields = {'training','baseline','shocked','irf'};
if all(isfield(result,single_fields))
    if ~isnumeric(result.path) || ~ismatrix(result.path)
        invalid('Single-run artifact path must be a numeric matrix.');
    end
elseif all(isfield(result,paired_fields))
    if ~isstruct(result.training) || ...
            (~isempty(result.baseline) && ~isstruct(result.baseline)) || ...
            (~isempty(result.shocked) && ~isstruct(result.shocked)) || ...
            ~isnumeric(result.irf)
        invalid('Paired simulation result is malformed.');
    end
else
    invalid('Artifact contains an unknown simulation-result shape.');
end
end

function result = contains_function_handle(value)
if isa(value,'function_handle')
    result = true;
elseif isstruct(value)
    result = any(arrayfun(@(index) any(cellfun( ...
        @contains_function_handle,struct2cell(value(index)))), ...
        1:numel(value)));
elseif iscell(value)
    result = any(cellfun(@contains_function_handle,value));
else
    result = false;
end
end

function invalid(message,varargin)
error('AdaptiveLearning:InvalidArtifact',message,varargin{:});
end
