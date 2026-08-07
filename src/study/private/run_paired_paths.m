function result = run_paired_paths(learning_system,restart_values, ...
    baseline_specification,shocked_specification)
%% RUN_PAIRED_PATHS Run baseline and shocked paths from one trained state.
% This is the shared composition primitive for both RUN_TRAINING_IRF and the
% reusable study-level RUN_IRF adapter. It contains no training loop and no
% artifact construction.

validate_learning_system(learning_system);
validate_experiment_specification(baseline_specification);
validate_experiment_specification(shocked_specification);
n = numel(learning_system.variable_names);
if ~isnumeric(restart_values) || ~isreal(restart_values) || ...
        ~isequal(size(restart_values),[n 1]) || ~all(isfinite(restart_values))
    error('AdaptiveLearning:IncompatibleHandoff', ...
        'Paired paths require one finite restart value per model variable.');
end
if baseline_specification.periods~=shocked_specification.periods || ...
        ~isequal(baseline_specification.initial_values(:), ...
        shocked_specification.initial_values(:))
    error('AdaptiveLearning:InvalidExperimentSpecification', ...
        'Baseline and shocked branches must have paired timing and starts.');
end

baseline_specification.initial_values = restart_values;
shocked_specification.initial_values = restart_values;
baseline = run_experiment(learning_system,baseline_specification);
shocked = run_experiment(learning_system,shocked_specification);

status = "completed";
termination = struct();
if baseline.status~="completed"
    status = baseline.status;
    termination = with_stage(baseline.termination,"baseline");
elseif shocked.status~="completed"
    status = shocked.status;
    termination = with_stage(shocked.termination,"shocked");
end
result = struct('baseline',baseline,'shocked',shocked, ...
    'irf',shocked.path-baseline.path,'status',status, ...
    'termination',termination);
end

function termination = with_stage(termination,stage)
termination.stage = stage;
end
