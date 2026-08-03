function result = run_nk_risk_premium_comparison(varargin)
%% RUN_NK_RISK_PREMIUM_COMPARISON Compare NK RE and EE after a demand shock.
% Research question: does one-step EE learning materially change real and
% nominal NK responses to an IID risk-premium innovation?
% This first benchmark uses an i.i.d. risk-premium process (rho_s=0). A unit
% eps_s innovation raises the gross premium by 0.01, which is one percentage
% point and one canonical deviation unit. Technology innovations remain zero.
%
% With no arguments, the runner uses the common 100-draw, 2,000-period, and
% gain-0.002 defaults. Alternatively supply both a complete E&P-style common
% experiment config and an output directory.

root = setup_project();
if nargin==0
    config = ep_experiment_config();
    output_dir = fullfile(root,'results','nk_risk_premium_comparison');
elseif nargin==2
    config = varargin{1};
    output_dir = varargin{2};
else
    error('EPResearch:RequiredArguments', ...
        'Supply both a complete config and output directory, or neither.');
end
validate_ep_experiment_config(config);
if ~isfolder(output_dir), mkdir(output_dir); end

model = load_nonlinear_dynare_model( ...
    fullfile(root,'models','nk_balanced_growth.mod'), ...
    'ParameterOverrides',struct('rho_s',0,'sigma_s',0.01), ...
    'DeviationScales',struct('gamma_x',0.01));

% The training standard deviation is expressed in one-percentage-point shock
% units. This is an illustrative common scale, not an empirical calibration of
% the risk-premium process.
shock_covariance = diag([0,config.training_shock_standard_deviation^2]);
learning_model = build_ee_learning_model(model, ...
    nk_risk_premium_ee_specification(config.gain),shock_covariance);
rng(config.random_seed,'twister');
standardized_innovations = zeros(config.draw_count, ...
    config.training_periods+config.ir_periods);
for draw = 1:config.draw_count
    standardized_innovations(draw,:) = randn(1, ...
        config.training_periods+config.ir_periods);
end
simulation = run_learning_specification(learning_model,'nk_risk_premium_ee', ...
    'NK risk-premium EE',standardized_innovations,config,1, ...
    @report_nk_nominal_quantities,'eps_s');

result = struct('experiment','nk_risk_premium_comparison','config',config, ...
    'shock_metadata',struct('name','eps_s','persistence',0, ...
    'innovation_scale',0.01,'impulse',1, ...
    'description',['i.i.d. one-percentage-point increase in the gross ' ...
    'risk premium; technology shocks fixed at zero']), ...
    'quantity_names',{{'output','consumption','investment','hours', ...
    'inflation','nominal rate'}}, ...
    'standardized_innovations',standardized_innovations, ...
    'simulation',simulation,'output_files',struct());
result.output_files = save_nk_risk_premium_panels(result,output_dir);
save(result.output_files.mat,'-struct','result','-v7.3');
end
