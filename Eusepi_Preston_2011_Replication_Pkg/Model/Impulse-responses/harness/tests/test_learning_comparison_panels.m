function test_learning_comparison_panels()
%% TEST_LEARNING_COMPARISON_PANELS Smoke-test common saved panels.

config=learning_comparison_config();
config.draw_count=2;
config.training_periods=40;
config.ir_periods=12;
config.plot_periods=1:12;
output_dir=tempname;
cleanup=onCleanup(@() remove_output(output_dir));
artifact=run_learning_comparison_panels(config,output_dir);
assert(isequal(artifact.specification_ids,{'ep_ee','ep_ih','nk_ee'}));
nk=artifact.results{3};
assert(nk.learning_specification.variant=="iid_comparison");
for j=1:3
    result=artifact.results{j};
    assert(abs(result.summary.re(1,1)-config.impact_output_percent)<1e-10);
    assert(result.status_counts.completed==config.draw_count);
    assert(isfile(fullfile(output_dir,result.id,'results.mat')));
end
assert(all(cellfun(@isfile,artifact.figure_files)));
assert(all(cellfun(@(file) dir(file).bytes>0,artifact.figure_files)));
assert(isfile(fullfile(output_dir,'comparison_results.mat')));
fprintf('Common E&P and NK learning panels passed.\n');
clear cleanup
end

function remove_output(path)
if isfolder(path), rmdir(path,'s'); end
end
