function test_initialization_robustness()
%% TEST_INITIALIZATION_ROBUSTNESS Verify common shocks and moderate priors.

config = ep_experiment_config();
config.draw_count = 2;
config.ir_periods = 4;
config.plot_periods = 1:4;
output = tempname;
cleanup = onCleanup(@() remove_output(output));
artifact = run_initialization_robustness(config,output);

assert(isequal(artifact.specification_ids,["ep_ee","ep_ih","nk_ee"]));
assert(isequal(artifact.initializations,["dynare_re","half_re"]));
assert(isequal(artifact.training_horizons,[0 100 500 2000]));
assert(isequal(size(artifact.results),[3 2 4]));
for specification = 1:3
    for horizon = 1:4
        re = artifact.results{specification,1,horizon}.initial_beliefs;
        half = artifact.results{specification,2,horizon}.initial_beliefs;
        assert(max(abs(half.coefficients-0.5*re.coefficients),[],'all')<1e-12);
        assert(~isequal(half.coefficients,re.coefficients));
        assert(isequal(half.moment_matrix,re.moment_matrix));
    end
end

rng(config.random_seed,'twister');
training = zeros(size(artifact.training_standardized_innovations));
ir = zeros(size(artifact.ir_standardized_innovations));
for draw = 1:config.draw_count
    sequence = randn(1,size(training,2)+size(ir,2));
    training(draw,:) = sequence(1:size(training,2));
    ir(draw,:) = sequence(size(training,2)+1:end);
end
assert(isequal(training,artifact.training_standardized_innovations));
assert(isequal(ir,artifact.ir_standardized_innovations));
assert(artifact.pairing.draw_by_draw);
assert(isequal(size(artifact.metrics.rates),[3 2 4 3]));
assert(isequal(size(artifact.metrics.relative_initialization_effect),[3 4 4]));
for name = {'mat','summary_csv','irf_pdf','irf_png','difference_pdf', ...
        'difference_png','summary_pdf','summary_png','appendix_pdf','appendix_png'}
    assert(isfile(artifact.output_files.(name{1})));
end
clear cleanup
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
