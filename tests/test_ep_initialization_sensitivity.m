function test_ep_initialization_sensitivity()
%% TEST_EP_INITIALIZATION_SENSITIVITY Check pairing, priors, and outputs.

config = ep_experiment_config();
config.draw_count = 3;
config.ir_periods = 5;
config.plot_periods = 1:5;
output = tempname;
cleanup = onCleanup(@() remove_output(output));
artifact = run_ep_initialization_sensitivity(config,output,[0 8]);

assert(isequal(artifact.initializations, ...
    ["dynare_re","half_re","zero_coefficients"]));
assert(isequal(size(artifact.results),[3 2]));
re = artifact.results{1,1}.initial_beliefs.coefficients;
assert(max(abs(artifact.results{2,1}.initial_beliefs.coefficients-0.5*re), ...
    [],'all')<1e-12);
assert(all(artifact.results{3,1}.initial_beliefs.coefficients==0,'all'));
assert(artifact.output_files.metrics.completion_fraction(1,1)==1);
assert(artifact.output_files.metrics.median_belief_distance_from_re(1,1)<1e-12);
assert(abs(artifact.output_files.metrics.median_belief_distance_from_re(2,1)- ...
    norm(0.5*re,'fro'))<1e-12);
assert(abs(artifact.output_files.metrics.median_belief_distance_from_re(3,1)- ...
    norm(re,'fro'))<1e-12);
for name = {'mat','pdf','png'}
    assert(isfile(artifact.output_files.(name{1})));
end
clear cleanup
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
