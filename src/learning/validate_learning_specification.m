function validate_learning_specification(specification)
%% VALIDATE_LEARNING_SPECIFICATION Validate declarative learning input.
% The active contract is defined in ARCHITECTURE.md. This validator checks
% properties intrinsic to one specification. Model-name resolution and shock
% dimension compatibility belong to COMPILE_LEARNING.

required = {'learned_variables','regressors','gain','estimator', ...
    'initialization','update_timing','projection','expectation_mapping'};
if ~isstruct(specification) || ~isscalar(specification) || ...
        ~isempty(setxor(fieldnames(specification),required.'))
    invalid('Learning specification fields do not match the contract.');
end
if contains_function_handle(specification)
    invalid('Learning specifications must not contain executable content.');
end

validate_names(specification.learned_variables,'learned_variables');
validate_regressors(specification.regressors);
validate_gain(specification.gain);
validate_estimator(specification.estimator);
validate_initialization(specification.initialization);

if text_scalar(specification.update_timing)~="decide_then_update"
    invalid('Unsupported learning update timing.');
end
validate_projection(specification.projection);
validate_expectation_mapping(specification.expectation_mapping);
end

function validate_regressors(regressors)
if ~iscell(regressors) || isempty(regressors) || ~isvector(regressors) || ...
        ~all(cellfun(@(value) isstruct(value) && isscalar(value),regressors))
    invalid('Regressors must be a nonempty cell array of descriptors.');
end
names = strings(numel(regressors),1);
for j = 1:numel(regressors)
    descriptor = regressors{j};
    if ~all(isfield(descriptor,{'name','kind'}))
        invalid('Every regressor requires name and kind fields.');
    end
    names(j) = text_scalar(descriptor.name);
    kind = text_scalar(descriptor.kind);
    switch kind
        case "constant"
            if ~isequal(sort(fieldnames(descriptor)),{'kind';'name'})
                invalid('A constant regressor has only name and kind fields.');
            end
        case "lagged_variable"
            expected = {'kind';'lag';'name';'variable'};
            if ~isequal(sort(fieldnames(descriptor)),expected) || ...
                    strlength(text_scalar(descriptor.variable))==0 || ...
                    ~positive_integer(descriptor.lag)
                invalid('Malformed lagged-variable regressor.');
            end
        otherwise
            invalid('Unsupported regressor kind "%s".',kind);
    end
end
if any(strlength(names)==0) || numel(unique(names))~=numel(names)
    invalid('Regressor names must be unique and nonempty.');
end
end

function validate_gain(gain)
if ~isstruct(gain) || ~isscalar(gain) || ~isfield(gain,'type')
    invalid('Gain must be a scalar policy struct.');
end
switch text_scalar(gain.type)
    case "constant"
        if ~isequal(sort(fieldnames(gain)),{'type';'value'}) || ...
                ~nonnegative_scalar(gain.value)
            invalid('Constant gain requires a finite nonnegative value.');
        end
    case "decreasing"
        if ~isequal(sort(fieldnames(gain)),{'offset';'type'}) || ...
                ~nonnegative_scalar(gain.offset)
            invalid('Decreasing gain requires a finite nonnegative offset.');
        end
    otherwise
        invalid('Unsupported gain schedule.');
end
end

function validate_estimator(estimator)
required = {'method';'moment_timing';'rcond_tolerance'};
if ~isstruct(estimator) || ~isscalar(estimator) || ...
        ~isequal(sort(fieldnames(estimator)),required) || ...
        text_scalar(estimator.method)~="rls" || ...
        text_scalar(estimator.moment_timing)~="update_before_coefficients" || ...
        ~positive_scalar(estimator.rcond_tolerance)
    invalid('Estimator does not match the supported RLS convention.');
end
end

function validate_initialization(initialization)
if ~isstruct(initialization) || ~isscalar(initialization) || ...
        ~isequal(sort(fieldnames(initialization)), ...
        {'coefficients';'moments'})
    invalid('Initialization requires coefficient and moment policies.');
end
coefficients = initialization.coefficients;
if ~isstruct(coefficients) || ~isscalar(coefficients) || ...
        ~isequal(sort(fieldnames(coefficients)),{'method';'scale'}) || ...
        text_scalar(coefficients.method)~="re" || ...
        ~nonnegative_scalar(coefficients.scale)
    invalid('Coefficient initialization must be a scaled RE policy.');
end
moments = initialization.moments;
if ~isstruct(moments) || ~isscalar(moments) || ...
        ~isequal(sort(fieldnames(moments)), ...
        {'method';'shock_covariance'}) || ...
        text_scalar(moments.method)~="stationary_re"
    invalid('Moment initialization must use the stationary RE policy.');
end
covariance = moments.shock_covariance;
if ~isnumeric(covariance) || ~isreal(covariance) || isempty(covariance) || ...
        size(covariance,1)~=size(covariance,2) || ...
        ~all(isfinite(covariance),'all') || ...
        norm(covariance-covariance','fro')>1e-12 || ...
        min(eig((covariance+covariance')/2)) < -1e-12
    invalid('Shock covariance must be finite and positive semidefinite.');
end
end

function validate_projection(projection)
if isempty(projection)
    return
end
required = {'action';'criterion';'limit';'regressor';'variable'};
if ~isstruct(projection) || ~isvector(projection)
    invalid('Projection must be empty or an array of rule structs.');
end
for j = 1:numel(projection)
    rule = projection(j);
    if ~isequal(sort(fieldnames(rule)),required) || ...
            strlength(text_scalar(rule.variable))==0 || ...
            strlength(text_scalar(rule.regressor))==0 || ...
            text_scalar(rule.criterion)~="absolute_limit" || ...
            ~positive_scalar(rule.limit) || ...
            text_scalar(rule.action)~="retain_previous_coefficient"
        invalid('Projection rule does not match the v1 contract.');
    end
end
end

function validate_expectation_mapping(mapping)
if ~isstruct(mapping) || ~isscalar(mapping) || ...
        ~isequal(sort(fieldnames(mapping)),{'method';'options'}) || ...
        ~isstruct(mapping.options) || ~isscalar(mapping.options)
    invalid('Expectation mapping requires method and options.');
end
switch text_scalar(mapping.method)
    case "one_step"
        if ~isempty(fieldnames(mapping.options))
            invalid('One-step expectation options must be empty in v1.');
        end
    case "infinite_horizon"
        validate_infinite_horizon_options(mapping.options);
    otherwise
        invalid('Unsupported expectation mapping.');
end
end

function validate_infinite_horizon_options(options)
required = {'decision_equation';'decision_forecast_targets';'feedback'; ...
    'forecast_targets';'present_value_equations';'present_value_variables'};
if ~isempty(setxor(fieldnames(options),required))
    invalid('Infinite-horizon expectation options are incomplete.');
end
validate_names(options.forecast_targets,'forecast_targets');
validate_names(options.present_value_variables,'present_value_variables');
validate_names(options.present_value_equations,'present_value_equations');
validate_names(options.decision_forecast_targets, ...
    'decision_forecast_targets');
if strlength(text_scalar(options.decision_equation))==0 || ...
        ~islogical(options.feedback) || ~isscalar(options.feedback)
    invalid('Infinite-horizon expectation options are malformed.');
end
end

function validate_names(value,label)
if isstring(value)
    names = value(:);
elseif iscell(value) && ~isempty(value) && all(cellfun( ...
        @(item) ischar(item) && isrow(item),value(:)))
    names = string(value(:));
else
    invalid('%s must be a nonempty text-name list.',label);
end
if isempty(names) || any(strlength(names)==0) || ...
        numel(unique(names))~=numel(names)
    invalid('%s must contain unique nonempty names.',label);
end
end

function value = text_scalar(input)
if ischar(input) && isrow(input)
    value = string(input);
elseif isstring(input) && isscalar(input)
    value = input;
else
    invalid('Expected a text scalar.');
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

function result = positive_integer(value)
result = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value>0 && value==fix(value);
end

function result = nonnegative_scalar(value)
result = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value>=0;
end

function result = positive_scalar(value)
result = nonnegative_scalar(value) && value>0;
end

function invalid(message,varargin)
error('AdaptiveLearning:InvalidLearningSpecification',message,varargin{:});
end
