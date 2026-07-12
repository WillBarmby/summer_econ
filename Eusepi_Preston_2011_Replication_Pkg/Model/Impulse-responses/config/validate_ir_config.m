function validate_ir_config(config)
%% VALIDATE_IR_CONFIG Enforce the complete impulse-response configuration contract.

require_exact_fields(config, {'baseline_seed','default_n_draws','main','model', ...
    'simulation_example'}, 'config');

required_main = {'impulse_horizon','training_sample_length','output_file', ...
    'output_var','store_output','learning','expectations_enabled', ...
    'impulse_response_enabled','feedback','shock_scale', ...
    'normalized_shock_size','band_upper_order_stat','band_lower_order_stat', ...
    'model_param','n_draws','output_dir','explosion_policy'};
require_exact_fields(config.main, required_main, 'config.main');

must_be_positive_integer(config.main.impulse_horizon, ...
    'IRConfig:InvalidImpulseHorizon','impulse_horizon');
if config.main.impulse_horizon < 2
    error('IRConfig:InvalidImpulseHorizon','impulse_horizon must be at least 2.');
end
must_be_positive_integer(config.main.training_sample_length, ...
    'IRConfig:InvalidTrainingLength','training_sample_length');
must_be_positive_integer(config.main.n_draws,'IRConfig:InvalidDrawCount','n_draws');

logical_fields = {'store_output','learning','expectations_enabled', ...
    'impulse_response_enabled','feedback'};
for j = 1:numel(logical_fields)
    value = config.main.(logical_fields{j});
    if ~islogical(value) || ~isscalar(value)
        error('IRConfig:InvalidLogical','config.main.%s must be a logical scalar.', ...
            logical_fields{j});
    end
end

must_be_finite_scalar(config.main.shock_scale,'shock_scale');
if config.main.shock_scale <= 0
    error('IRConfig:InvalidShockScale','shock_scale must be positive.');
end
must_be_finite_scalar(config.main.normalized_shock_size,'normalized_shock_size');
if ~isnumeric(config.main.model_param) || numel(config.main.model_param) ~= 6 || ...
        any(~isfinite(config.main.model_param(:)))
    error('IRConfig:InvalidModelParameters', ...
        'model_param must contain exactly six finite numeric values.');
end

validate_band(config.main.band_lower_order_stat,config.main.n_draws,'band_lower_order_stat');
validate_band(config.main.band_upper_order_stat,config.main.n_draws,'band_upper_order_stat');

if config.main.store_output
    require_text(config.main.output_dir,'output_dir');
    require_text(config.main.output_file,'output_file');
    require_text(config.main.output_var,'output_var');
end

policy = config.main.explosion_policy;
require_exact_fields(policy, {'magnitude_limit','reject_nonfinite','variable_indices'}, ...
    'config.main.explosion_policy');
must_be_finite_scalar(policy.magnitude_limit,'explosion_policy.magnitude_limit');
if policy.magnitude_limit <= 0
    error('IRConfig:InvalidExplosionPolicy','magnitude_limit must be positive.');
end
if ~islogical(policy.reject_nonfinite) || ~isscalar(policy.reject_nonfinite)
    error('IRConfig:InvalidExplosionPolicy','reject_nonfinite must be a logical scalar.');
end
if ~isnumeric(policy.variable_indices) || ~isvector(policy.variable_indices) || ...
        isempty(policy.variable_indices) || any(policy.variable_indices < 1) || ...
        any(policy.variable_indices ~= floor(policy.variable_indices))
    error('IRConfig:InvalidExplosionPolicy', ...
        'variable_indices must be a nonempty vector of positive integers.');
end
end

function require_exact_fields(value, required, label)
if ~isstruct(value) || ~isscalar(value)
    error('IRConfig:InvalidStruct','%s must be a scalar struct.',label);
end
actual = fieldnames(value).';
missing = setdiff(required,actual,'stable');
unknown = setdiff(actual,required,'stable');
if ~isempty(missing)
    error('IRConfig:MissingField','%s is missing field(s): %s.',label,strjoin(missing,', '));
end
if ~isempty(unknown)
    error('IRConfig:UnknownField','%s has unknown field(s): %s.',label,strjoin(unknown,', '));
end
end

function must_be_positive_integer(value,id,label)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value < 1 || value ~= floor(value)
    error(id,'%s must be a positive integer.',label);
end
end

function must_be_finite_scalar(value,label)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('IRConfig:InvalidScalar','%s must be a finite numeric scalar.',label);
end
end

function validate_band(value,n_draws,label)
must_be_positive_integer(value,'IRConfig:InvalidBandIndex',label);
if value > n_draws
    error('IRConfig:InvalidBandIndex','%s must not exceed n_draws.',label);
end
end

function require_text(value,label)
if ~(ischar(value) || (isstring(value) && isscalar(value))) || strlength(string(value)) == 0
    error('IRConfig:InvalidText','%s must be nonempty text.',label);
end
end
