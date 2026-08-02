function artifact = run_initialization_robustness(varargin)
%% RUN_INITIALIZATION_ROBUSTNESS Compare moderate priors across all models.
% Exact RE and half-RE coefficients receive identical shocks draw by draw.
% The default is the paper comparison: 100 draws, 2,000 training observations,
% gain 0.002, and E&P EE, E&P IH, and NK EE specifications.

root = setup_project();
if nargin==0
    config = ep_experiment_config();
    output_dir = fullfile(root,'results','initialization_robustness');
elseif nargin==2
    config = varargin{1};
    output_dir = varargin{2};
else
    error('EPResearch:RequiredArguments', ...
        'Supply neither argument or both a configuration and output directory.');
end
validate_ep_experiment_config(config);
assert(config.training_periods==2000 && abs(config.gain-0.002)<eps, ...
    'EPResearch:InitializationDesign', ...
    'The harmonized comparison fixes training at 2,000 and gain at 0.002.');
if ~isfolder(output_dir), mkdir(output_dir); end

cases = initialization_robustness_cases(root,config);
initializations = ["dynare_re","half_re"];
rng(config.random_seed,'twister');
innovations = zeros(config.draw_count,config.training_periods+config.ir_periods);
for draw = 1:config.draw_count
    innovations(draw,:) = randn(1,size(innovations,2));
end

results = cell(numel(cases),2);
for specification = 1:numel(cases)
    for treatment = 1:2
        learning_model = set_initial_beliefs( ...
            cases(specification).learning_model,initializations(treatment));
        results{specification,treatment} = run_learning_specification( ...
            learning_model,sprintf('%s_%s',cases(specification).id, ...
            initializations(treatment)),sprintf('%s, %s initialization', ...
            cases(specification).label,initializations(treatment)), ...
            innovations,config,config.technology_growth_impulse, ...
            @report_common_quantities,'eps_x');
    end
end

artifact = struct('experiment','initialization_robustness', ...
    'interpretation',['Common moderate-prior comparison; zero coefficients ' ...
    'and global attraction remain separate stress tests.'], ...
    'config',config,'specification_ids',{string({cases.id})}, ...
    'specification_labels',{{cases.label}},'initializations',initializations, ...
    'quantity_names',{{'output','consumption','investment','hours'}}, ...
    'standardized_innovations',innovations, ...
    'pairing',struct('draw_by_draw',true,'source_field', ...
    'standardized_innovations','fingerprint',innovation_fingerprint(innovations)), ...
    'results',{results},'metrics',struct(),'output_files',struct());
artifact.metrics = summarize_initialization_robustness(artifact);
artifact.output_files = save_initialization_robustness(artifact,output_dir);
save(artifact.output_files.mat,'-struct','artifact','-v7.3');
end

function value = innovation_fingerprint(innovations)
weights = reshape(1:numel(innovations),size(innovations));
value = [size(innovations),sum(innovations,'all'), ...
    sum(innovations.^2,'all'),sum(weights.*innovations,'all')];
end
