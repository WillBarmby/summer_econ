function test_ep_public_interface()
%% TEST_EP_PUBLIC_INTERFACE Exercise saved metadata, pairing, and figures.

setup_project();
test_setup_path_independence();
config = ep_experiment_config();
config.draw_count = 2;
config.training_periods = 20;
config.ir_periods = 8;
config.plot_periods = 1:8;
output = tempname;
mkdir(output);
cleanup = onCleanup(@() rmdir(output,'s'));

first = run_ep_comparison(config,fullfile(output,'first'));
second = run_ep_comparison(config,fullfile(output,'second'));
assert(isequal(first.standardized_innovations,second.standardized_innovations));
assert(max(abs(first.results{1}.learning_draws- ...
    second.results{1}.learning_draws),[],'all')<1e-12);
assert(isequal(first.results{1}.statuses,second.results{1}.statuses));
assert(first.shock_metadata.impulse==1);
assert(first.shock_metadata.training_standard_deviation==exp(-0.034));
assert(first.calibration.gamma_bar==exp(0.0053));
assert(first.results{1}.learning_specification.variant== ...
    "paper_direct_consumption");
assert(first.results{2}.learning_specification.formulation=="infinite_horizon");
assert(isequal(size(first.results{1}.terminal_training_coefficients),[2 3 2]));
assert(all(first.results{1}.training_projection_events>=0));
for name = {'mat','pdf','png'}
    assert(isfile(first.output_files.(name{1})), ...
        'Missing public-interface output: %s.',name{1});
end
saved = load(first.output_files.mat,'config','calibration','shock_metadata', ...
    'results','output_files');
assert(isequal(saved.config,first.config));
assert(isequal(saved.calibration,first.calibration));
assert(isequal(saved.shock_metadata,first.shock_metadata));
assert(isequal(saved.results{1}.statuses,first.results{1}.statuses));
assert(isequal(saved.results{1}.terminal_training_coefficients, ...
    first.results{1}.terminal_training_coefficients));
assert(isequal(saved.output_files,first.output_files));

growth_config = config;
growth_config.draw_count = 1;
growth = run_ep_growth_sensitivity(growth_config,fullfile(output,'growth'));
assert(growth.baseline.calibration.gamma_bar==exp(0.0053));
assert(growth.zero_growth.calibration.gamma_bar==1);
assert(isequal(growth.baseline.standardized_innovations, ...
    growth.zero_growth.standardized_innovations));
assert(isfile(growth.output_file));
assert(isfile(growth.figure_files.pdf) && isfile(growth.figure_files.png));
clear cleanup
fprintf('Clean E&P public interface passed reproducibility and output checks.\n');
end
