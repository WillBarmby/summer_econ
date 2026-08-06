function result = run_training_irf(learning_system,specification)
%% RUN_TRAINING_IRF Train once, then run paired baseline and shocked paths.
% This function composes RUN_EXPERIMENT. It contains no simulation loop and
% does not mutate the caller's compiled learning system.

validate_learning_system(learning_system);
validate_composition_specification(specification);

training = run_experiment(learning_system,specification.training);
if training.status~="completed"
    result = struct( ...
        'training',training, ...
        'baseline',[], ...
        'shocked',[], ...
        'irf',[], ...
        'status',training.status, ...
        'termination',with_stage(training.termination,"training"));
    return
end

trained_system = learning_system;
trained_system.initial_beliefs = training.terminal_beliefs;
validate_learning_system(trained_system);
baseline = run_experiment(trained_system,specification.baseline);
shocked = run_experiment(trained_system,specification.shocked);

status = "completed";
termination = struct();
if baseline.status~="completed"
    status = baseline.status;
    termination = with_stage(baseline.termination,"baseline");
elseif shocked.status~="completed"
    status = shocked.status;
    termination = with_stage(shocked.termination,"shocked");
end
result = struct( ...
    'training',training, ...
    'baseline',baseline, ...
    'shocked',shocked, ...
    'irf',shocked.path-baseline.path, ...
    'status',status, ...
    'termination',termination);
end

function validate_composition_specification(specification)
required = {'baseline';'shocked';'training'};
if ~isstruct(specification) || ~isscalar(specification) || ...
        ~isequal(sort(fieldnames(specification)),required)
    error('AdaptiveLearning:InvalidExperimentSpecification', ...
        'Training/IRF composition requires three experiment specifications.');
end
validate_experiment_specification(specification.training);
validate_experiment_specification(specification.baseline);
validate_experiment_specification(specification.shocked);
if specification.baseline.periods~=specification.shocked.periods || ...
        ~isequal(specification.baseline.initial_values(:), ...
        specification.shocked.initial_values(:))
    error('AdaptiveLearning:InvalidExperimentSpecification', ...
        'Baseline and shocked branches must have paired timing and starts.');
end
end

function termination = with_stage(termination,stage)
termination.stage = stage;
end
