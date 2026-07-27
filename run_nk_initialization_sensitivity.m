function sensitivity = run_nk_initialization_sensitivity(varargin)
%% RUN_NK_INITIALIZATION_SENSITIVITY Compare RE and naive initial forecasts.
% Agents either start from the exact RE PLM or set every learned PLM intercept
% and capital slope to zero. Structural knowledge, information, gain, shocks,
% and RLS moment initialization are otherwise identical. Training horizons are
% nested prefixes of the same histories.

root = setup_project();
default_horizons = [0 100 500 2000];
if nargin==0
    config = ep_experiment_config();
    output_dir = fullfile(root,'results','nk_initialization_sensitivity');
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
assert(isnumeric(horizons) && isrow(horizons) && ~isempty(horizons) && ...
    all(horizons>=0) && all(mod(horizons,1)==0) && ...
    numel(unique(horizons))==numel(horizons), ...
    'EPResearch:InvalidTrainingHorizons', ...
    'Training horizons must be unique nonnegative integers.');
if ~isfolder(output_dir), mkdir(output_dir); end

model = load_nonlinear_dynare_model( ...
    fullfile(root,'models','nk_balanced_growth.mod'), ...
    'DeviationScales',struct('gamma_x',0.01));

%% Create nested training histories and one common post-training history.
rng(config.random_seed,'twister');
maximum_training = max(horizons);
training_master = zeros(config.draw_count,maximum_training);
ir_master = zeros(config.draw_count,config.ir_periods);
for draw = 1:config.draw_count
    sequence = randn(1,maximum_training+config.ir_periods);
    training_master(draw,:) = sequence(1:maximum_training);
    ir_master(draw,:) = sequence(maximum_training+1:end);
end

initializations = ["dynare_re","zero_coefficients"];
results = cell(numel(initializations),numel(horizons));
for initial = 1:numel(initializations)
    for j = 1:numel(horizons)
        training_periods = horizons(j);
        case_config = config;
        case_config.training_periods = training_periods;
        innovations = [training_master(:,1:training_periods),ir_master];
        learning_model = build_ee_learning_model(model, ...
            nk_ee_specification(config.gain), ...
            diag([config.training_shock_standard_deviation^2,0]));
        learning_model = set_initial_beliefs(learning_model, ...
            initializations(initial));
        results{initial,j} = run_learning_specification(learning_model, ...
            sprintf('nk_%s_training_%d',initializations(initial),training_periods), ...
            sprintf('NK %s',initializations(initial)),innovations,case_config, ...
            config.technology_growth_impulse,@report_common_quantities,'eps_x');
    end
end

sensitivity = struct('experiment','nk_initialization_sensitivity', ...
    'config',config,'training_horizons',horizons, ...
    'default_training_horizons',default_horizons, ...
    'initializations',initializations, ...
    'quantity_names',{{'output','consumption','investment','hours'}}, ...
    'training_standardized_innovations',training_master, ...
    'ir_standardized_innovations',ir_master,'results',{results}, ...
    'output_files',struct());
sensitivity.output_files = save_nk_initialization_sensitivity( ...
    sensitivity,output_dir);
save(sensitivity.output_files.mat,'-struct','sensitivity','-v7.3');
end
