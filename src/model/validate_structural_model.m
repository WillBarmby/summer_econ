function validate_structural_model(structural_model)
%% VALIDATE_STRUCTURAL_MODEL Validate the active structural-model contract.
% The contract is defined in ARCHITECTURE.md. A structural model contains
% only the equation-residual representation and its metadata:
%
%   D0*y_t + Dlag*y_(t-1) + Dlead*y_(t+1) + Dshock*eps_t = 0.
%
% It is deliberately not a reduced-form RE solution and must not carry
% Dynare runtime state, learning machinery, or experiment configuration.

required = {'current','lag','lead','shock', ...
    'variable_names','shock_names','equation_names', ...
    'calibration','transformation'};
if ~isstruct(structural_model) || ~isscalar(structural_model)
    invalid('Structural model must be a scalar struct.');
end

for j = 1:numel(required)
    if ~isfield(structural_model,required{j})
        invalid('Structural model lacks field "%s".',required{j});
    end
end

forbidden = {'re','dynare','decision_rule','learning', ...
    'learning_system','initial_beliefs','belief_to_plm','plm_to_alm', ...
    'regressor','outcome','updater','shocks','shock_schedule', ...
    'experiment','experiment_specification','output_path','reporting'};
leakage = intersect(fieldnames(structural_model),forbidden);
if ~isempty(leakage)
    invalid('Structural model contains forbidden field "%s".',leakage{1});
end

variable_names = validate_names(structural_model.variable_names, ...
    'variable_names');
shock_names = validate_names(structural_model.shock_names,'shock_names');
equation_names = validate_names(structural_model.equation_names, ...
    'equation_names');
n = numel(variable_names);
q = numel(shock_names);
if n==0
    invalid('Structural model must contain at least one variable.');
end
if numel(equation_names)~=n
    invalid('A square structural system requires one equation per variable.');
end

validate_matrix(structural_model.current,[n n],'current');
validate_matrix(structural_model.lag,[n n],'lag');
validate_matrix(structural_model.lead,[n n],'lead');
validate_matrix(structural_model.shock,[n q],'shock');

if ~isstruct(structural_model.calibration) || ...
        ~isscalar(structural_model.calibration)
    invalid('Calibration must be a scalar metadata struct.');
end
if ~isstruct(structural_model.transformation) || ...
        ~isscalar(structural_model.transformation)
    invalid('Transformation must be a scalar metadata struct.');
end
end

function names = validate_names(value,field_name)
if isstring(value)
    names = value(:);
elseif iscell(value) && all(cellfun(@(item) ischar(item) && ...
        isrow(item),value(:)))
    names = string(value(:));
else
    invalid('%s must be a one-dimensional list of text names.',field_name);
end
if isempty(names) || any(strlength(names)==0) || numel(unique(names))~=numel(names)
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
error('AdaptiveLearning:InvalidStructuralModel',message,varargin{:});
end
