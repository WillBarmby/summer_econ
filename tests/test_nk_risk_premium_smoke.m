function test_nk_risk_premium_smoke()
%% TEST_NK_RISK_PREMIUM_SMOKE Verify shock isolation and saved output files.

config = ep_experiment_config();
config.draw_count = 1;
config.training_periods = 8;
config.ir_periods = 5;
config.plot_periods = 1:5;
output = tempname;
cleanup = onCleanup(@() remove_output(output));
result = run_nk_risk_premium_comparison(config,output);
assert(result.simulation.status_counts.completed==1);
assert(result.shock_metadata.persistence==0 && ...
    result.shock_metadata.innovation_scale==0.01);

% The selected impulse moves the premium on impact while the technology-growth
% row remains zero. This catches accidental use of eps_x in the two-shock model.
names = result.simulation.variable_names;
risk_index = find(strcmp(names,'risk_premium'),1);
growth_index = find(strcmp(names,'gamma_x'),1);
native = result.simulation.re_native_path;
assert(abs(native(risk_index,1)-1)<1e-10);
assert(max(abs(native(growth_index,:)))<1e-12);
assert(isfile(result.output_files.mat) && isfile(result.output_files.pdf) && ...
    isfile(result.output_files.png));
clear cleanup
fprintf('NK risk-premium runner passed its shock-isolation smoke test.\n');
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
