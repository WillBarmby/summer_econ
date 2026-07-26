function artifact = run_ep_experiment(config,output_dir,experiment_name)
%% RUN_EP_EXPERIMENT Execute paired paper-EE and benchmark-IH simulations.
% One seeded matrix of standardized innovations is reused for both learning
% models. Each draw trains once, then compares baseline and shocked paths from
% identical terminal values and beliefs. Failed draws are recorded, not replaced.

validate_ep_experiment_config(config);
if ~isfolder(output_dir), mkdir(output_dir); end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
calibration = ep_calibration(config.gamma_bar);
models = {load_linear_dynare_model(fullfile(root,'models','ep_rbc_ee.mod'), ...
    'ParameterOverrides',calibration.parameter_overrides), ...
    load_linear_dynare_model(fullfile(root,'models','ep_rbc_ih.mod'), ...
    'ParameterOverrides',calibration.parameter_overrides)};
learning_models = {build_ee_learning_model(models{1}, ...
    ep_ee_specification(config.gain),config.training_shock_standard_deviation^2), ...
    build_ep_ih_learning_model(models{2},ep_ih_specification(config.gain), ...
    config.training_shock_standard_deviation^2)};
ids = {'ep_ee','ep_ih'};
labels = {'E&P paper-faithful EE','E&P benchmark IH'};

rng(config.random_seed,'twister');
standardized_innovations = zeros(config.draw_count, ...
    config.training_periods+config.ir_periods);
% Generate one row per draw to preserve the exact seeded RNG consumption of
% the verified implementation. A single matrix-valued randn call fills data
% columnwise and would produce a different (though statistically equivalent)
% sample under the same seed.
for draw = 1:config.draw_count
    standardized_innovations(draw,:) = randn(1, ...
        config.training_periods+config.ir_periods);
end
results = cell(1,2);
for j = 1:2
    results{j} = run_learning_model(learning_models{j},ids{j},labels{j}, ...
        standardized_innovations,config);
end
artifact = struct('experiment',experiment_name, ...
    'config',config,'calibration',calibration, ...
    'shock_metadata',struct('name','eps_x', ...
    'training_standard_deviation',config.training_shock_standard_deviation, ...
    'impulse',config.technology_growth_impulse, ...
    'impulse_description',[ ...
    'one-percentage-point technology-growth innovation; E&P native unit = 1']), ...
    'quantity_names',{{'output','consumption','investment','hours'}}, ...
    'specification_ids',{ids},'specification_labels',{labels}, ...
    'standardized_innovations',standardized_innovations,'results',{results}, ...
    'output_files',struct());
artifact.output_files = save_ep_artifact_and_panels(artifact,output_dir);
% Save again so the MAT file records its own complete output-file manifest.
save(artifact.output_files.mat,'-struct','artifact','-v7.3');
end

function result = run_learning_model(learning_model,id,label,innovations,config)
n = numel(learning_model.model.variable_names);
q = numel(learning_model.model.shock_names);
assert(q==1,'EPResearch:ShockContract','E&P interface requires one shock.');
impulse = config.technology_growth_impulse;
re_native = make_re_irf(learning_model,config.ir_periods,impulse);
re_reported = report_ep_quantities(re_native,learning_model.model.variable_names);
raw = NaN(config.draw_count,4,config.ir_periods);
statuses = strings(config.draw_count,1);
terminations = cell(config.draw_count,1);
policy = struct('magnitude_limit',config.explosion_magnitude, ...
    'reject_nonfinite',true,'variable_indices',1:n);
for draw = 1:config.draw_count
    common = innovations(draw,:)*config.training_shock_standard_deviation;
    training = common(1:config.training_periods);
    ir_shocks = common(config.training_periods+1:end);
    paired = simulate_paired_irf(learning_model,training,ir_shocks,impulse, ...
        zeros(n,1),learning_model.initial_beliefs,policy);
    statuses(draw) = paired.status;
    if paired.status=="completed"
        raw(draw,:,:) = report_ep_quantities(paired.native_irf, ...
            learning_model.model.variable_names);
        terminations{draw} = struct();
    else
        terminations{draw} = find_termination(paired);
    end
end
completed = statuses=="completed";
summary = summarize_learning_draws(raw,re_reported,config.band_probabilities);
result = struct('id',id,'label',label,'model_name',learning_model.model.name, ...
    'backend',learning_model.model.backend, ...
    'effective_calibration',learning_model.model.calibration, ...
    'variable_names',{learning_model.model.variable_names}, ...
    'learning_specification',learning_model.specification, ...
    're_native_path',re_native,'re_reported_path',re_reported, ...
    'learning_draws',raw,'summary',summary,'statuses',statuses, ...
    'terminations',{terminations},'status_counts',struct( ...
    'completed',sum(completed),'explosive',sum(contains(statuses,"explosive")), ...
    'invalid',sum(contains(statuses,"invalid"))));
end

function termination = find_termination(paired)
for name = {'training','baseline','shocked'}
    run = paired.(name{1});
    if ~isempty(run) && run.status~="completed"
        termination = run.termination;
        termination.stage = name{1};
        return
    end
end
termination = struct();
end
