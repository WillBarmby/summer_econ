function artifact = run_initialization_robustness(varargin)
%% RUN_INITIALIZATION_ROBUSTNESS Compare moderate priors across all models.
% Research question: how much do IRFs depend on exact-RE versus half-RE starting
% coefficients, and how quickly does common training remove that dependence?
% Exact RE and half-RE coefficients receive identical shocks draw by draw.
% The paper comparison uses 100 draws, gain 0.002, and nested training samples
% of 0, 100, 500, and 2,000 observations in all three specifications.

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
training_horizons = [0 100 500 2000];
rng(config.random_seed,'twister');
training_innovations = zeros(config.draw_count,max(training_horizons));
ir_innovations = zeros(config.draw_count,config.ir_periods);
for draw = 1:config.draw_count
    sequence = randn(1,max(training_horizons)+config.ir_periods);
    training_innovations(draw,:) = sequence(1:max(training_horizons));
    ir_innovations(draw,:) = sequence(max(training_horizons)+1:end);
end

results = cell(numel(cases),2,numel(training_horizons));
for specification = 1:numel(cases)
    for treatment = 1:2
        for horizon = 1:numel(training_horizons)
            periods = training_horizons(horizon);
            case_config = config;
            case_config.training_periods = periods;
            innovations = [training_innovations(:,1:periods),ir_innovations];
            learning_model = set_initial_beliefs( ...
                cases(specification).learning_model,initializations(treatment));
            results{specification,treatment,horizon} = run_learning_specification( ...
                learning_model,sprintf('%s_%s_training_%d', ...
                cases(specification).id,initializations(treatment),periods), ...
                sprintf('%s, %s initialization',cases(specification).label, ...
                initializations(treatment)),innovations,case_config, ...
                config.technology_growth_impulse,@report_common_quantities,'eps_x');
        end
    end
end

artifact = struct('experiment','initialization_robustness', ...
    'interpretation',['Common moderate-prior comparison; zero coefficients ' ...
    'and global attraction remain separate stress tests.'], ...
    'config',config,'specification_ids',{string({cases.id})}, ...
    'specification_labels',{{cases.label}},'initializations',initializations, ...
    'training_horizons',training_horizons, ...
    'quantity_names',{{'output','consumption','investment','hours'}}, ...
    'training_standardized_innovations',training_innovations, ...
    'ir_standardized_innovations',ir_innovations, ...
    'pairing',struct('draw_by_draw',true,'source_field', ...
    'training_standardized_innovations and ir_standardized_innovations', ...
    'fingerprint',innovation_fingerprint([training_innovations ir_innovations])), ...
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
