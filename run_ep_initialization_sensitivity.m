function sensitivity = run_ep_initialization_sensitivity(varargin)
%% RUN_EP_INITIALIZATION_SENSITIVITY Compare E&P EE forecasting priors.
% Agents begin with the Dynare RE forecasting coefficients, one-half of those
% coefficients, or zero coefficients. Everything else—the structural model,
% information set, RLS moment matrix, gain, shocks, and update timing—is held
% fixed. Training horizons are nested prefixes of the same random histories.

root = setup_project();
default_horizons = [0 100 500 2000];
if nargin==0
    config = ep_experiment_config();
    output_dir = fullfile(root,'results','ep_initialization_sensitivity');
    horizons = default_horizons;
elseif nargin==2 || nargin==3
    config = varargin{1};
    output_dir = varargin{2};
    if nargin==3, horizons = varargin{3}; else, horizons = default_horizons; end
else
    error('EPResearch:RequiredArguments', ...
        'Supply neither, config and output directory, or those plus horizons.');
end
validate_ep_experiment_config(config);
validate_horizons(horizons);
if ~isfolder(output_dir), mkdir(output_dir); end

calibration = ep_calibration(config.gamma_bar);
model = load_linear_dynare_model(fullfile(root,'models','ep_rbc_ee.mod'), ...
    'ParameterOverrides',calibration.parameter_overrides);

%% Draw each complete history once, then reuse its nested training prefixes.
% This pairing means differences across priors and horizons cannot be caused
% by different random samples. The post-training IR innovations also remain
% identical in every treatment.
rng(config.random_seed,'twister');
maximum_training = max(horizons);
training_master = zeros(config.draw_count,maximum_training);
ir_master = zeros(config.draw_count,config.ir_periods);
for draw = 1:config.draw_count
    sequence = randn(1,maximum_training+config.ir_periods);
    training_master(draw,:) = sequence(1:maximum_training);
    ir_master(draw,:) = sequence(maximum_training+1:end);
end

initializations = ["dynare_re","half_re","zero_coefficients"];
results = cell(numel(initializations),numel(horizons));
for initial = 1:numel(initializations)
    for j = 1:numel(horizons)
        training_periods = horizons(j);
        case_config = config;
        case_config.training_periods = training_periods;
        innovations = [training_master(:,1:training_periods),ir_master];
        learning_model = build_ee_learning_model(model, ...
            ep_ee_specification(config.gain), ...
            config.training_shock_standard_deviation^2);
        learning_model = set_initial_beliefs(learning_model, ...
            initializations(initial));
        results{initial,j} = run_learning_specification(learning_model, ...
            sprintf('ep_ee_%s_training_%d',initializations(initial),training_periods), ...
            sprintf('E&P EE %s',initializations(initial)),innovations,case_config, ...
            config.technology_growth_impulse,@report_common_quantities,'eps_x');
    end
end

sensitivity = struct('experiment','ep_initialization_sensitivity', ...
    'interpretation',['Paper-faithful E&P EE initialization robustness ' ...
    'experiment; not a replication claim.'], ...
    'config',config,'calibration',calibration, ...
    'training_horizons',horizons, ...
    'default_training_horizons',default_horizons, ...
    'initializations',initializations, ...
    'quantity_names',{{'output','consumption','investment','hours'}}, ...
    'training_standardized_innovations',training_master, ...
    'ir_standardized_innovations',ir_master,'results',{results}, ...
    'output_files',struct());
sensitivity.output_files = save_ep_initialization_sensitivity( ...
    sensitivity,output_dir);
save(sensitivity.output_files.mat,'-struct','sensitivity','-v7.3');
end

function validate_horizons(horizons)
assert(isnumeric(horizons) && isrow(horizons) && ~isempty(horizons) && ...
    all(horizons>=0) && all(mod(horizons,1)==0) && ...
    numel(unique(horizons))==numel(horizons), ...
    'EPResearch:InvalidTrainingHorizons', ...
    'Training horizons must be unique nonnegative integers.');
end
