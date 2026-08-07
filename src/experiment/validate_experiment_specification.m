function validate_experiment_specification(specification)
%% VALIDATE_EXPERIMENT_SPECIFICATION Validate one simulation request.
% This single-value validator checks intrinsic configuration. Model-relative
% dimensions are checked by RUN_EXPERIMENT at the public handoff.

required = {'initial_values','shocks','periods', ...
    'explosion_policy','store_belief_history'};
if ~isstruct(specification) || ~isscalar(specification) || ...
        ~isempty(setxor(fieldnames(specification),required.'))
    invalid('Experiment specification fields do not match the contract.');
end
if ~finite_vector(specification.initial_values)
    invalid('Initial values must be a nonempty finite real vector.');
end
if ~nonnegative_integer(specification.periods)
    invalid('Periods must be a nonnegative integer.');
end
if ~isnumeric(specification.shocks) || ~isreal(specification.shocks) || ...
        ~ismatrix(specification.shocks) || ...
        ~all(isfinite(specification.shocks),'all')
    invalid('Shocks must be a finite real matrix.');
end
if size(specification.shocks,2)~=specification.periods
    error('AdaptiveLearning:InvalidShockSchedule', ...
        'The shock schedule must have one column per period.');
end
validate_explosion_policy(specification.explosion_policy);
if ~islogical(specification.store_belief_history) || ...
        ~isscalar(specification.store_belief_history)
    invalid('store_belief_history must be a logical scalar.');
end
end

function validate_explosion_policy(policy)
required = {'magnitude_limit';'reject_nonfinite';'variable_indices'};
if ~isstruct(policy) || ~isscalar(policy) || ...
        ~isequal(sort(fieldnames(policy)),required) || ...
        ~positive_scalar(policy.magnitude_limit) || ...
        ~islogical(policy.reject_nonfinite) || ...
        ~isscalar(policy.reject_nonfinite)
    invalid('Explosion policy does not match the contract.');
end
indices = policy.variable_indices;
if ~isnumeric(indices) || ~isreal(indices) || isempty(indices) || ...
        ~isvector(indices) || ~all(isfinite(indices)) || ...
        any(indices<1) || any(indices~=fix(indices)) || ...
        numel(unique(indices))~=numel(indices)
    invalid('Monitored variable indices must be unique positive integers.');
end
end

function result = finite_vector(value)
result = isnumeric(value) && isreal(value) && ~isempty(value) && ...
    isvector(value) && all(isfinite(value));
end

function result = nonnegative_integer(value)
result = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value>=0 && value==fix(value);
end

function result = positive_scalar(value)
result = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value>0;
end

function invalid(message,varargin)
error('AdaptiveLearning:InvalidExperimentSpecification',message,varargin{:});
end
