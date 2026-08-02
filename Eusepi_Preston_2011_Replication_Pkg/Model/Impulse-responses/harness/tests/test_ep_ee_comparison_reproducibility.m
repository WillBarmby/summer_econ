function test_ep_ee_comparison_reproducibility()
%% TEST_EP_EE_COMPARISON_REPRODUCIBILITY Same seed gives identical draws.

output_file=fullfile(tempdir,'ep_ee_comparison_reproducibility.mat');
cleanup=onCleanup(@() remove_outputs(output_file)); %#ok<NASGU>
config=make_ep_ee_comparison_config(2,output_file);
config.bootstrap_reps=50;

first=run_ep_ee_specification_comparison(config);
second=run_ep_ee_specification_comparison(config);

assert(isequaln(first.draw_data,second.draw_data), ...
    'EPEE:NonDeterministicDraws','Matched draw-level results changed at a fixed seed.');
assert(isequaln(first.moment_summary,second.moment_summary), ...
    'EPEE:NonDeterministicSummary','Bootstrap summaries changed at a fixed seed.');
assert(isequaln(first.status_summary,second.status_summary), ...
    'EPEE:NonDeterministicStatus','Status summaries changed at a fixed seed.');
fprintf('E&P EE matched-comparison reproducibility test passed.\n');
end

function remove_outputs(output_file)
[directory,name]=fileparts(output_file);
paths={output_file,fullfile(directory,[name '.md']), ...
    fullfile(directory,[name '_moments.csv']), ...
    fullfile(directory,[name '_statuses.csv'])};
for j=1:numel(paths)
    if isfile(paths{j}), delete(paths{j}); end
end
end
