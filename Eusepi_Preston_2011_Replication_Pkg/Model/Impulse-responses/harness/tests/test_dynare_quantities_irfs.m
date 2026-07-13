function test_dynare_quantities_irfs()
%% TEST_DYNARE_QUANTITIES_IRFS Compare public workflow with legacy draws.

experiment=make_dynare_ir_config();
experiment.draw_count=2;
experiment.training_periods=80;
experiment.ir_periods=40;
output_dir=tempname; cleanup=onCleanup(@() remove_output(output_dir));
model_dir=fileparts(fileparts(mfilename('fullpath')));
try
    run_dynare_quantities_irfs(fullfile(model_dir,'models','ep13_ih_re_linear.mod'), ...
        ep_ih_learning_config(),make_ir_config(),output_dir);
    error('Test:ExpectedFailure','Legacy-shaped experiment config was accepted.');
catch exception
    assert(strcmp(exception.identifier,'DynareIR:InvalidExperiment'));
end
artifact=run_dynare_quantities_irfs( ...
    fullfile(model_dir,'models','ep13_ih_re_linear.mod'), ...
    ep_ih_learning_config(),experiment,output_dir);

rng(experiment.random_seed,'twister');
indices=ir_variable_indices();
legacy_config=make_ir_config();
legacy_config.main.n_draws=experiment.draw_count;
legacy_config.main.training_sample_length=experiment.training_periods;
legacy_config.main.impulse_horizon=experiment.ir_periods+1;
legacy_config.main.shock_scale=experiment.shock.simulation_scale;
legacy_config.main.normalized_shock_size=experiment.shock.impulse_size;
legacy_config.main.explosion_policy=experiment.explosion_policy;
for draw_index=1:experiment.draw_count
    innovations=randn(1,experiment.training_periods+experiment.ir_periods+1);
    legacy=simulate_ir_draw(legacy_config.main,innovations,indices);
    expected=legacy.ir_series([2 4 3 6],:);
    actual=squeeze(artifact.raw_quantities(draw_index,:,:));
    assert(max(abs(actual-expected),[],'all')<1e-10);
end
assert(isequal(artifact.plot_data.band_probabilities,[0.25 0.75]));
assert(all(artifact.plot_data.learning_low<=artifact.plot_data.learning_high,'all'));
assert(all(cellfun(@isfile,artifact.figure_files)));
assert(all(cellfun(@(file) dir(file).bytes>0,artifact.figure_files)));
fprintf('Dynare quantities workflow parity tests passed.\n');
clear cleanup
end

function remove_output(path)
if isfolder(path), rmdir(path,'s'); end
end
