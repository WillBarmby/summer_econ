function contract = resolve_learning_contract(model,solution,specification)
%% RESOLVE_LEARNING_CONTRACT Resolve public names once at compilation.

if ~isequal(string(model.variable_names),string(solution.variable_names)) || ...
        ~isequal(string(model.shock_names),string(solution.shock_names))
    incompatible('Structural-model and RE declarations do not match.');
end

[found,learned_indices] = ismember( ...
    specification.learned_variables,model.variable_names);
if ~all(found)
    unknown('Unknown learned variable "%s".', ...
        string(specification.learned_variables(find(~found,1))));
end

k = numel(specification.regressors);
regressor_indices = zeros(1,k);
regressor_kinds = strings(1,k);
regressor_names = cell(1,k);
for j = 1:k
    descriptor = specification.regressors{j};
    regressor_names{j} = char(string(descriptor.name));
    regressor_kinds(j) = string(descriptor.kind);
    if regressor_kinds(j)=="lagged_variable"
        [found,index] = ismember(char(string(descriptor.variable)), ...
            model.variable_names);
        if ~found
            unknown('Unknown regressor variable "%s".',descriptor.variable);
        end
        if descriptor.lag~=1
            invalid(['The v1 affine PLM supports only first-lag variables; ' ...
                'higher lags require an augmented-state contract.']);
        end
        regressor_indices(j) = index;
    end
end

covariance = specification.initialization.moments.shock_covariance;
q = numel(model.shock_names);
if ~isequal(size(covariance),[q q])
    incompatible('Initialization shock covariance must be q-by-q.');
end

projection_rows = zeros(1,numel(specification.projection));
projection_columns = zeros(1,numel(specification.projection));
for j = 1:numel(specification.projection)
    rule = specification.projection(j);
    [found,projection_rows(j)] = ismember( ...
        char(string(rule.variable)),specification.learned_variables);
    if ~found
        unknown('Projection variable "%s" is not learned.',rule.variable);
    end
    [found,projection_columns(j)] = ismember( ...
        char(string(rule.regressor)),regressor_names);
    if ~found
        unknown('Projection regressor "%s" is not declared.',rule.regressor);
    end
end

contract = struct( ...
    'learned_indices',learned_indices(:).', ...
    'regressor_indices',regressor_indices, ...
    'regressor_kinds',regressor_kinds, ...
    'regressor_names',{regressor_names}, ...
    'projection_rows',projection_rows, ...
    'projection_columns',projection_columns);
end

function unknown(message,varargin)
error('AdaptiveLearning:UnknownVariable',message,varargin{:});
end

function invalid(message,varargin)
error('AdaptiveLearning:InvalidLearningSpecification',message,varargin{:});
end

function incompatible(message,varargin)
error('AdaptiveLearning:IncompatibleHandoff',message,varargin{:});
end
