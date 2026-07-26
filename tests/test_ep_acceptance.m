function test_ep_acceptance()
%% TEST_EP_ACCEPTANCE Reproduce retained 100-draw E&P summary fixtures.
% The fixture contains only reference outputs and provenance. This test runs
% the clean engine twice and never imports code or model files from the frozen
% replication package.

root = fileparts(fileparts(mfilename('fullpath')));
fixture = load(fullfile(root,'tests','fixtures', ...
    'ep_experiment_reference.mat'),'reference');
config = ep_experiment_config();
output = tempname;
cleanup = onCleanup(@() remove_output(output));

baseline = run_ep_comparison(config,fullfile(output,'baseline'));
compare_results(baseline.results,fixture.reference.baseline,'baseline');
zero_config = config;
zero_config.gamma_bar = 1;
zero_growth = run_ep_comparison(zero_config,fullfile(output,'zero_growth'));
compare_results(zero_growth.results,fixture.reference.zero_growth,'zero growth');
assert(isfile(baseline.output_files.mat) && isfile(baseline.output_files.pdf) && ...
    isfile(baseline.output_files.png),'EPResearch:AcceptanceOutput', ...
    'The full acceptance run did not generate every output file.');
clear cleanup
fprintf('Full E&P baseline and growth summaries match verified fixtures.\n');
end

function compare_results(actual,reference,label)
for j = 1:2
    assert(strcmp(actual{j}.id,reference{j}.id), ...
        'EPResearch:AcceptanceIdentity','Specification order changed.');
    assert(isequal(actual{j}.statuses(:),reference{j}.statuses(:)), ...
        'EPResearch:AcceptanceStatuses','%s statuses changed for %s.', ...
        label,actual{j}.id);
    assert(isequal(actual{j}.status_counts,reference{j}.status_counts), ...
        'EPResearch:AcceptanceStatuses','%s status counts changed for %s.', ...
        label,actual{j}.id);
    compare_matrix(actual{j}.summary.learning_median, ...
        reference{j}.learning_median,label,actual{j}.id,'median');
    compare_matrix(actual{j}.summary.learning_low, ...
        reference{j}.learning_low,label,actual{j}.id,'lower band');
    compare_matrix(actual{j}.summary.learning_high, ...
        reference{j}.learning_high,label,actual{j}.id,'upper band');
    compare_matrix(actual{j}.summary.re,reference{j}.re, ...
        label,actual{j}.id,'RE path');
end
end

function compare_matrix(actual,reference,label,id,quantity)
error_value = max(abs(actual-reference),[],'all');
assert(error_value<1e-10,'EPResearch:AcceptanceValue', ...
    '%s %s changed for %s (maximum error %.3g).',label,quantity,id,error_value);
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
