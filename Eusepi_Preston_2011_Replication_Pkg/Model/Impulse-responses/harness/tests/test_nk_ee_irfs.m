function test_nk_ee_irfs()
%% TEST_NK_EE_IRFS Smoke-test the public NK RE-versus-EE experiment.

config=nk_ee_ir_config();
config.draw_count=2;
config.training_periods=40;
config.ir_periods=12;
config.plot_periods=1:12;
output_dir=tempname;
cleanup=onCleanup(@() remove_output(output_dir));
artifact=run_nk_ee_irfs(config,output_dir);

output=find(strcmp(artifact.variable_names,'output'),1);
assert(artifact.calibration_variant=="iid_comparison");
assert(artifact.effective_calibration.rho_technology==0);
assert(abs(100*artifact.raw_re_irf(output,1)-config.impact_output_percent)<1e-10);
assert(artifact.status_counts.completed==config.draw_count);
assert(isequal(size(artifact.raw_learning_irfs), ...
    [config.draw_count,numel(artifact.variable_names),config.ir_periods]));
assert(artifact.reporting.percent_multiplier==100);
assert(artifact.reporting.annualized_percentage_point_multiplier==400);
assert(abs(artifact.reported_summary.re(output,1)-config.impact_output_percent)<1e-10);
assert(isfile(fullfile(output_dir,'nk_ee_irfs.mat')));
assert(all(cellfun(@isfile,artifact.figure_files)));
assert(all(cellfun(@(file) dir(file).bytes>0,artifact.figure_files)));
fprintf('NK EE public IR workflow passed.\n');
clear cleanup
end

function remove_output(path)
if isfolder(path), rmdir(path,'s'); end
end
