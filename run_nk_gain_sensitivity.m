function sensitivity = run_nk_gain_sensitivity(varargin)
%% RUN_NK_GAIN_SENSITIVITY Map NK EE amplification across learning gains.
% Research question: how does the gain alter NK EE amplification under separate
% technology and IID risk-premium shocks?
% The documented grid is [0, .002, .005, .01, .02]. Every gain receives the
% same standardized histories. Technology and i.i.d. risk-premium experiments
% are kept separate, and all failed draws remain recorded rather than replaced.
%
% Usage:
%   result = run_nk_gain_sensitivity();
%   result = run_nk_gain_sensitivity(config,output_directory);
%   result = run_nk_gain_sensitivity(config,output_directory,gain_grid);
% The third form is intended for tests or an explicitly documented alternative.

root = setup_project();
default_gains = [0 0.002 0.005 0.01 0.02];
if nargin==0
    config = ep_experiment_config();
    output_dir = fullfile(root,'results','nk_gain_sensitivity');
    gains = default_gains;
elseif nargin==2 || nargin==3
    config = varargin{1};
    output_dir = varargin{2};
    if nargin==3, gains = varargin{3}; else, gains = default_gains; end
else
    error('EPResearch:RequiredArguments', ...
        'Supply neither, config and output directory, or those plus gains.');
end
validate_ep_experiment_config(config);
assert(isnumeric(gains) && isrow(gains) && ~isempty(gains) && ...
    all(isfinite(gains)) && all(gains>=0) && numel(unique(gains))==numel(gains), ...
    'EPResearch:InvalidGainGrid','Gains must be unique nonnegative values.');
if ~isfolder(output_dir), mkdir(output_dir); end

%% Load one two-shock NK model for both isolated experiments.
% rho_s=0 keeps the premium innovation unpredictable, making omission from the
% PLM coherent. sigma_s=.01 makes a unit eps_s a one-percentage-point premium
% innovation. The unused shock is set exactly to zero by the shared runner.
model = load_nonlinear_dynare_model( ...
    fullfile(root,'models','nk_balanced_growth.mod'), ...
    'ParameterOverrides',struct('rho_s',0,'sigma_s',0.01), ...
    'DeviationScales',struct('gamma_x',0.01));

%% Generate the single random-number design shared by every case.
rng(config.random_seed,'twister');
standardized_innovations = zeros(config.draw_count, ...
    config.training_periods+config.ir_periods);
for draw = 1:config.draw_count
    standardized_innovations(draw,:) = randn(1, ...
        config.training_periods+config.ir_periods);
end

technology_results = cell(1,numel(gains));
risk_results = cell(1,numel(gains));
for j = 1:numel(gains)
    gain = gains(j);
    technology_model = build_ee_learning_model(model,nk_ee_specification(gain), ...
        diag([config.training_shock_standard_deviation^2,0]));
    technology_results{j} = run_learning_specification(technology_model, ...
        sprintf('nk_technology_gain_%g',gain),'NK technology EE', ...
        standardized_innovations,config,config.technology_growth_impulse, ...
        @report_common_quantities,'eps_x');

    risk_model = build_ee_learning_model(model, ...
        nk_risk_premium_ee_specification(gain), ...
        diag([0,config.training_shock_standard_deviation^2]));
    risk_results{j} = run_learning_specification(risk_model, ...
        sprintf('nk_risk_gain_%g',gain),'NK risk-premium EE', ...
        standardized_innovations,config,1,@report_nk_nominal_quantities,'eps_s');
end

sensitivity = struct('experiment','nk_gain_sensitivity','config',config, ...
    'gains',gains,'default_gains',default_gains, ...
    'metric_description',['maximum over plotted periods of the absolute ' ...
    'median learning-minus-own-RE response'], ...
    'technology_quantity_names',{{'output','consumption','investment','hours'}}, ...
    'risk_quantity_names',{{'output','consumption','investment','hours', ...
    'inflation','nominal rate'}}, ...
    'standardized_innovations',standardized_innovations, ...
    'technology_results',{technology_results},'risk_results',{risk_results}, ...
    'output_files',struct());
sensitivity.output_files = save_nk_gain_sensitivity(sensitivity,output_dir);
save(sensitivity.output_files.mat,'-struct','sensitivity','-v7.3');
end
