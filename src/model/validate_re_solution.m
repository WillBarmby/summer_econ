function validate_re_solution(re_solution)
%% VALIDATE_RE_SOLUTION Validate the active reduced-form RE contract.
% The contract is defined in ARCHITECTURE.md. This value is the clean law
% handed from SOLVE_RE to learning code; it is not Dynare's decision-rule
% object and it does not contain the structural model or experiment state.

required = {'intercept','transition','shock','state_indices', ...
    'variable_names','shock_names'};
if ~isstruct(re_solution) || ~isscalar(re_solution)
    invalid('RE solution must be a scalar struct.');
end
for j = 1:numel(required)
    if ~isfield(re_solution,required{j})
        invalid('RE solution lacks field "%s".',required{j});
    end
end

forbidden = {'decision_rule','dynare','M_','oo_','model', ...
    'learning_system','experiment','experiment_specification'};
leakage = intersect(fieldnames(re_solution),forbidden);
if ~isempty(leakage)
    invalid('RE solution contains forbidden field "%s".',leakage{1});
end

variable_names = validate_names(re_solution.variable_names, ...
    'variable_names',false);
shock_names = validate_names(re_solution.shock_names,'shock_names',true);
n = numel(variable_names);
q = numel(shock_names);

validate_matrix(re_solution.intercept,[n 1],'intercept');
validate_matrix(re_solution.transition,[n n],'transition');
validate_matrix(re_solution.shock,[n q],'shock');

states = re_solution.state_indices;
if ~isnumeric(states) || ~isreal(states) || ~isvector(states) || ...
        ~all(isfinite(states),'all') || any(states~=fix(states),'all') || ...
        any(states<1 | states>n) || numel(unique(states))~=numel(states)
    invalid('state_indices must be unique integer indices between 1 and n.');
end
end

function names = validate_names(value,field_name,allow_empty)
if isstring(value)
    names = value(:);
elseif iscell(value) && all(cellfun(@(item) ischar(item) && ...
        isrow(item),value(:)))
    names = string(value(:));
else
    invalid('%s must be a one-dimensional list of text names.',field_name);
end
if (~allow_empty && isempty(names)) || any(strlength(names)==0) || ...
        numel(unique(names))~=numel(names)
    invalid('%s must contain unique, nonempty names.',field_name);
end
end

function validate_matrix(value,expected_size,field_name)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value),expected_size) || ~all(isfinite(value),'all')
    invalid('%s must be a finite real %d-by-%d matrix.', ...
        field_name,expected_size(1),expected_size(2));
end
end

function invalid(message,varargin)
error('AdaptiveLearning:InvalidRESolution',message,varargin{:});
end
