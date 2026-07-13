function test_dynare_quantities_irfs()
%% TEST_DYNARE_QUANTITIES_IRFS Compare public workflow with legacy draws.

experiment=make_ir_config();
experiment.main.n_draws=2;
experiment.main.training_sample_length=80;
experiment.main.impulse_horizon=41;
output_dir=tempname; cleanup=onCleanup(@() remove_output(output_dir));
model_dir=fileparts(fileparts(mfilename('fullpath')));
artifact=run_dynare_quantities_irfs( ...
    fullfile(model_dir,'models','ep13_ih_re_linear.mod'), ...
    ep_ih_learning_config(),experiment,output_dir);

rng(experiment.baseline_seed,'twister');
indices=ir_variable_indices();
for draw_index=1:experiment.main.n_draws
    innovations=randn(1,experiment.main.training_sample_length+ ...
        experiment.main.impulse_horizon);
    legacy=simulate_ir_draw(experiment.main,innovations,indices);
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
