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
    'projection_columns',projection_columns, ...
    'expectation',resolve_expectation_contract( ...
        model,specification.expectation_mapping));
end

function expectation = resolve_expectation_contract(model,mapping)
method = string(mapping.method);
expectation = struct('method',method);
if method=="one_step"
    return
end
options = mapping.options;
present_values = options.present_values;
target_indices = zeros(1,numel(present_values));
variable_indices = zeros(1,numel(present_values));
equation_indices = zeros(1,numel(present_values));
target_scales = zeros(1,numel(present_values));
for j = 1:numel(present_values)
    target_indices(j) = index_of( ...
        model.variable_names,present_values(j).target,'variable');
    variable_indices(j) = index_of( ...
        model.variable_names,present_values(j).variable,'variable');
    equation_indices(j) = index_of( ...
        model.equation_names,present_values(j).equation,'equation');
    target_scales(j) = present_values(j).target_scale;
end
decision = options.decision;
expectation.discount = options.discount;
expectation.present_value_target_indices = target_indices;
expectation.present_value_variable_indices = variable_indices;
expectation.present_value_equation_indices = equation_indices;
expectation.present_value_target_scales = target_scales;
expectation.decision_equation_index = index_of( ...
    model.equation_names,decision.equation,'equation');
expectation.decision_remove_indices = indices_of( ...
    model.variable_names,decision.remove_variables,'variable');
expectation.decision_target_indices = indices_of( ...
    model.variable_names,decision.forecast_targets,'variable');
expectation.decision_weights = decision.forecast_weights(:).';
end

function indices = indices_of(names,requested,kind)
indices = zeros(1,numel(requested));
for j = 1:numel(requested)
    indices(j) = index_of(names,string(requested(j)),kind);
end
end

function index = index_of(names,requested,kind)
[found,index] = ismember(string(requested),string(names));
if ~found
    error('AdaptiveLearning:UnknownName', ...
        'Unknown %s name "%s".',kind,string(requested));
end
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
