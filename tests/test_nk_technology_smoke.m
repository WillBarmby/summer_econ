function test_nk_technology_smoke()
%% TEST_NK_TECHNOLOGY_SMOKE Verify nominal technology-shock reporting.

config = ep_experiment_config();
config.draw_count = 1;
config.training_periods = 8;
config.ir_periods = 5;
config.plot_periods = 1:5;
output = tempname;
cleanup = onCleanup(@() remove_output(output));
result = run_nk_technology_comparison(config,output);

assert(result.simulation.status_counts.completed==1);
assert(isequal(result.quantity_names, ...
    {'output','consumption','investment','hours','inflation','nominal rate'}));
names = result.simulation.variable_names;
premium_index = find(strcmp(names,'risk_premium'),1);
growth_index = find(strcmp(names,'gamma_x'),1);
native = result.simulation.re_native_path;
assert(max(abs(native(premium_index,:)))<1e-12);
assert(abs(native(growth_index,1)-1)<1e-10);
assert(result.simulation.re_reported_path(5,1)>0 && ...
    result.simulation.re_reported_path(6,1)>0);
assert(all(isfinite(result.simulation.re_reported_path),'all'));
assert(isfile(result.output_files.mat) && isfile(result.output_files.pdf) && ...
    isfile(result.output_files.png) && isfile(result.output_files.summary_csv));
assert(result.schema_version=="2.0.0" && ...
    isequal(size(result.summary. ...
    maximum_absolute_median_learning_minus_re_wedge),[1 6]));
clear cleanup
fprintf('NK technology nominal IRF smoke test passed.\n');
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
