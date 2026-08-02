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
assert(isequal(size(artifact.results),[3 2]));
for specification = 1:3
    re = artifact.results{specification,1}.initial_beliefs;
    half = artifact.results{specification,2}.initial_beliefs;
    assert(max(abs(half.coefficients-0.5*re.coefficients),[],'all')<1e-12);
    assert(~isequal(half.coefficients,re.coefficients));
    assert(isequal(half.moment_matrix,re.moment_matrix));
end

rng(config.random_seed,'twister');
expected = zeros(size(artifact.standardized_innovations));
for draw = 1:config.draw_count
    expected(draw,:) = randn(1,size(expected,2));
end
assert(isequal(expected,artifact.standardized_innovations));
assert(artifact.pairing.draw_by_draw);
assert(isequal(size(artifact.metrics.rates),[3 2 3]));
assert(isequal(size(artifact.metrics.relative_initialization_effect),[3 4]));
for name = {'mat','summary_csv','irf_pdf','irf_png','difference_pdf', ...
        'difference_png','summary_pdf','summary_png'}
    assert(isfile(artifact.output_files.(name{1})));
end
clear cleanup
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
