function test_ep_ih_initialization_robustness()
%% TEST_EP_IH_INITIALIZATION_ROBUSTNESS Verify pairing and treatment isolation.

config = ep_experiment_config();
config.draw_count = 2;
config.ir_periods = 4;
config.plot_periods = 1:4;
output = tempname;
cleanup = onCleanup(@() remove_output(output));
artifact = run_ep_ih_initialization_robustness(config,output);

assert(isequal(artifact.initializations,["dynare_re","half_re"]));
re = artifact.results{1}.initial_beliefs;
half = artifact.results{2}.initial_beliefs;
assert(max(abs(half.coefficients-0.5*re.coefficients),[],'all')<1e-12);
assert(isequal(half.moment_matrix,re.moment_matrix));
assert(~isequal(half.coefficients,re.coefficients));
assert(artifact.pairing.draw_by_draw);
assert(isequal(artifact.pairing.innovation_fingerprint(1,:), ...
    artifact.pairing.innovation_fingerprint(2,:)));

% Reconstruct the seeded rows to prove the saved common source is unchanged.
rng(config.random_seed,'twister');
expected = zeros(size(artifact.standardized_innovations));
for draw = 1:config.draw_count
    expected(draw,:) = randn(1,size(expected,2));
end
assert(isequal(expected,artifact.standardized_innovations));
assert(all(size(artifact.output_files.metrics.rates)==[2 3]));
assert(all(size(artifact.output_files.metrics.draw_level_re_minus_half_response)== ...
    [config.draw_count 4 config.ir_periods]));
for name = {'mat','irf_pdf','irf_png','diagnostics_pdf','diagnostics_png'}
    assert(isfile(artifact.output_files.(name{1})));
end
clear cleanup
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
