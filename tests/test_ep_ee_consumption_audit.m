function test_ep_ee_consumption_audit()
%% TEST_EP_EE_CONSUMPTION_AUDIT Smoke-test pairing, metrics, and saved files.

config = ep_experiment_config();
config.draw_count = 1;
config.ir_periods = 4;
config.plot_periods = 1:4;
output = tempname;
cleanup = onCleanup(@() remove_output(output));
artifact = run_ep_ee_consumption_audit(config,output);

assert(isequal(artifact.variants, ...
    ["paper_direct_consumption","archive_fixed_re_consumption"]));
assert(artifact.pairing.draw_by_draw);
assert(isequal(artifact.pairing.innovation_fingerprint(1,:), ...
    artifact.pairing.innovation_fingerprint(2,:)));
assert(artifact.results{1}.learning_specification.consumption_forecast.mode== ...
    "learned_outcome");
assert(artifact.results{2}.learning_specification.consumption_forecast.mode== ...
    "fixed_re");
metrics = artifact.summary;
assert(isequal(size(metrics.rates),[2 3]));
assert(isequal(size(metrics.conditional_learning_minus_re_irf),[1 4 4 2]));
assert(isequal(size(metrics.draw_level_direct_minus_archive_irf),[1 4 4]));
assert(isequal(size(metrics.maximum_absolute_learning_minus_re_wedge),[1 4 2]));
for name = {'mat','comparison_pdf','comparison_png','difference_pdf', ...
        'difference_png','diagnostics_pdf','diagnostics_png','summary_csv'}
    assert(isfile(artifact.output_files.(name{1})));
end
assert(artifact.schema_version=="2.0.0");
assert(all(cellfun(@(value) ischar(value) || isstring(value), ...
    struct2cell(artifact.output_files))));
clear cleanup
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
