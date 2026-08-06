function validate_learning_system(learning_system)
%% VALIDATE_LEARNING_SYSTEM Validate the compiled learning handoff.
% The compiled value is executable, but remains inspectable through its name
% lists and belief dimensions. Experiment and reporting state are forbidden.

required = {'variable_names','shock_names','learned_variables', ...
    'regressor_names','initial_beliefs','belief_to_plm','plm_to_alm', ...
    'regressor','outcome','updater'};
if ~isstruct(learning_system) || ~isscalar(learning_system)
    invalid('Learning system must be a scalar struct.');
end
for j = 1:numel(required)
    if ~isfield(learning_system,required{j})
        invalid('Learning system lacks field "%s".',required{j});
    end
end

forbidden = {'model','structural_model','re_solution','specification', ...
    'shocks','shock_schedule','periods','initial_values','experiment', ...
    'experiment_specification','output_path','reporting','figures'};
leakage = intersect(fieldnames(learning_system),forbidden);
if ~isempty(leakage)
    invalid('Learning system contains forbidden field "%s".',leakage{1});
end

variable_names = names(learning_system.variable_names,'variable_names');
names(learning_system.shock_names,'shock_names');
learned_variables = names(learning_system.learned_variables, ...
    'learned_variables');
regressor_names = names(learning_system.regressor_names,'regressor_names');
if ~all(ismember(learned_variables,variable_names))
    invalid('Every learned variable must be a declared model variable.');
end

callbacks = {'belief_to_plm','plm_to_alm','regressor','outcome','updater'};
for j = 1:numel(callbacks)
    if ~isa(learning_system.(callbacks{j}),'function_handle')
        invalid('%s must be a function handle.',callbacks{j});
    end
end

beliefs = learning_system.initial_beliefs;
belief_fields = {'coefficients','moment_matrix','observations', ...
    'projection_events','invalid'};
if ~isstruct(beliefs) || ~isscalar(beliefs) || ...
        ~all(isfield(beliefs,belief_fields))
    invalid('Initial beliefs do not match the compiled-state contract.');
end
m = numel(learned_variables);
k = numel(regressor_names);
if ~finite_matrix(beliefs.coefficients,[m k])
    invalid('Initial coefficients must be learned-variable-by-regressor.');
end
if ~finite_matrix(beliefs.moment_matrix,[k k]) || ...
        norm(beliefs.moment_matrix-beliefs.moment_matrix','fro')>1e-12 || ...
        min(eig((beliefs.moment_matrix+beliefs.moment_matrix')/2)) < -1e-12
    invalid('Initial moment matrix must be symmetric positive semidefinite.');
end
if ~nonnegative_integer(beliefs.observations) || ...
        ~nonnegative_integer(beliefs.projection_events) || ...
        ~islogical(beliefs.invalid) || ~isscalar(beliefs.invalid)
    invalid('Initial belief counters or invalid flag are malformed.');
end
end

function value = names(input,label)
if isstring(input)
    value = input(:);
elseif iscell(input) && ~isempty(input) && all(cellfun( ...
        @(item) ischar(item) && isrow(item),input(:)))
    value = string(input(:));
else
    invalid('%s must be a nonempty text-name list.',label);
end
if isempty(value) || any(strlength(value)==0) || ...
        numel(unique(value))~=numel(value)
    invalid('%s must contain unique nonempty names.',label);
end
end

function result = finite_matrix(value,expected_size)
result = isnumeric(value) && isreal(value) && ...
    isequal(size(value),expected_size) && all(isfinite(value),'all');
end

function result = nonnegative_integer(value)
result = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value>=0 && value==fix(value);
end

function invalid(message,varargin)
error('AdaptiveLearning:InvalidLearningSystem',message,varargin{:});
end
