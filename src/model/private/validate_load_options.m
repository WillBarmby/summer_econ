function options = validate_load_options(input_options)
%% VALIDATE_LOAD_OPTIONS Normalize options before touching Dynare.
% Keeping option validation outside LOAD_MODEL makes the public function's
% first step explicit and gives configuration failures stable identifiers.

if ~isstruct(input_options) || ~isscalar(input_options)
    error('AdaptiveLearning:InvalidModelOptions', ...
        'Model options must be a scalar struct.');
end

options = struct('kind',"linear",'parameter_overrides',struct(), ...
    'deviation_scales',struct());
if isfield(input_options,'kind')
    kind = input_options.kind;
    if ischar(kind)
        kind = string(kind);
    end
    if ~isstring(kind) || ~isscalar(kind)
        error('AdaptiveLearning:InvalidModelOptions', ...
            'Model option kind must be a text scalar.');
    end
    options.kind = lower(kind);
end
if ~any(options.kind==["linear" "nonlinear"])
    error('AdaptiveLearning:UnsupportedModelKind', ...
        'Model kind must be "linear" or "nonlinear".');
end

if isfield(input_options,'parameter_overrides')
    overrides = input_options.parameter_overrides;
    if ~isstruct(overrides) || ~isscalar(overrides)
        error('AdaptiveLearning:InvalidModelOptions', ...
            'Parameter overrides must be a scalar struct.');
    end
    names = fieldnames(overrides);
    for j = 1:numel(names)
        value = overrides.(names{j});
        if ~isvarname(names{j}) || ~isnumeric(value) || ~isscalar(value) || ...
                ~isreal(value) || ~isfinite(value)
            error('AdaptiveLearning:InvalidModelOptions', ...
                'Parameter overrides require finite real scalar values.');
        end
    end
    options.parameter_overrides = overrides;
end

if isfield(input_options,'deviation_scales')
    scales = input_options.deviation_scales;
    if ~isstruct(scales) || ~isscalar(scales)
        error('AdaptiveLearning:InvalidModelOptions', ...
            'Deviation scales must be a scalar struct.');
    end
    names = fieldnames(scales);
    for j = 1:numel(names)
        value = scales.(names{j});
        if ~isvarname(names{j}) || ~isnumeric(value) || ~isscalar(value) || ...
                ~isreal(value) || ~isfinite(value) || value<=0
            error('AdaptiveLearning:InvalidModelOptions', ...
                'Deviation scales require positive finite scalar values.');
        end
    end
    options.deviation_scales = scales;
end
if options.kind=="linear" && ~isempty(fieldnames(options.deviation_scales))
    error('AdaptiveLearning:InvalidModelOptions', ...
        'Explicit linear models use unit scales and accept no scale overrides.');
end
end
