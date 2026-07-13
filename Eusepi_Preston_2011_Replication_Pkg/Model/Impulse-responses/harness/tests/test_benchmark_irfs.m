function test_benchmark_irfs()
%% TEST_BENCHMARK_IRFS Verify graph mappings, bands, files, and failure policy.

config = make_ir_config();
config.main.n_draws = 3;
config.main.store_output = false;
output_dir = tempname;
artifact = run_benchmark_irfs(config,benchmark_plot_spec(0,0),output_dir);
assert(numel(artifact.figure_files)==8 && all(cellfun(@isfile,artifact.figure_files)));
assert(numel(artifact.plot_data)==16,'Expected fourteen reported series and two sums.');
assert(isequal(artifact.plot_spec.periods,1:40));
assert(isequal(artifact.plot_spec.band_probabilities,[0.15 0.85]));
for series = 1:numel(artifact.plot_data)
    values = sort(artifact.learning_raw{series},1);
    assert(isequaln(artifact.plot_data(series).learning_low,values(1,:)));
    assert(isequaln(artifact.plot_data(series).learning_high,values(3,:)));
end

config.main.n_draws = 1;
config.main.explosion_policy.magnitude_limit = realmin;
failed = false;
try
    run_benchmark_irfs(config,benchmark_plot_spec(0,0),tempname);
catch exception
    failed = strcmp(exception.identifier,'IRBenchmark:NoCompletedDraws');
end
assert(failed,'A benchmark with no completed draws must fail explicitly.');
fprintf('Benchmark IRF graph workflow tests passed.\n');
end
