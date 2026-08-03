function test_ep_smoke()
%% TEST_EP_SMOKE Run one short draw and verify every public output type.

config = ep_experiment_config();
config.draw_count = 1;
config.training_periods = 8;
config.ir_periods = 5;
config.plot_periods = 1:5;
output = tempname;
cleanup = onCleanup(@() remove_output(output));
artifact = run_ep_comparison(config,output);
assert(all(cellfun(@(result) result.status_counts.completed==1, ...
    artifact.results)),'EPResearch:SmokeFailure', ...
    'The short E&P simulation did not complete.');
assert(isfile(artifact.output_files.mat) && ...
    isfile(artifact.output_files.pdf) && isfile(artifact.output_files.png) && ...
    isfile(artifact.output_files.summary_csv), ...
    'EPResearch:SmokeFailure','MAT, figure, or CSV output is missing.');
assert(artifact.schema_version=="2.0.0" && ...
    isequal(artifact.periods.horizons,0:config.ir_periods-1));
clear cleanup
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
