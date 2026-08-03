function test_standard_artifact_schema()
%% TEST_STANDARD_ARTIFACT_SCHEMA Exercise cross-model and gain CSV contracts.

config = ep_experiment_config();
config.draw_count = 1;
config.training_periods = 8;
config.ir_periods = 4;
config.plot_periods = 1:4;
gains = [0 0.002];
output = tempname;
cleanup = onCleanup(@() remove_output(output));

cross = run_cross_model_comparison(config,fullfile(output,'cross'));
check_common_contract(cross,12);
assert(isequal(size(cross.summary. ...
    maximum_absolute_median_learning_minus_re_wedge),[3 4]));

gain = run_gain_sensitivity_comparison(config,fullfile(output,'gain'),gains);
check_common_contract(gain,24);
assert(isequal(size(gain.summary. ...
    maximum_absolute_median_learning_minus_re_wedge),[3 2 4]));
assert(~isfield(gain.output_files,'wedge_metric'));
assert(isfield(gain.output_files,'summary_csv'));

nk = run_nk_gain_sensitivity(config,fullfile(output,'nk_gain'),gains);
check_common_contract(nk,20);
assert(isequal(size(nk.summary.technology. ...
    maximum_absolute_median_learning_minus_re_wedge),[1 2 4]));
assert(isequal(size(nk.summary.risk_premium. ...
    maximum_absolute_median_learning_minus_re_wedge),[1 2 6]));
assert(~isfield(nk.output_files,'technology_metric'));

clear cleanup
fprintf('Standard artifact schema and CSV contracts passed.\n');
end

function check_common_contract(artifact,expected_csv_rows)
required = {'schema_version','question','units','periods','axes', ...
    'provenance','summary','output_files'};
assert(all(isfield(artifact,required)));
assert(artifact.schema_version=="2.0.0" && strlength(artifact.question)>0);
assert(isequal(artifact.periods.horizons,0:artifact.config.ir_periods-1));
assert(isfile(artifact.output_files.summary_csv));
values = struct2cell(artifact.output_files);
assert(all(cellfun(@(value) ischar(value) || isstring(value),values)), ...
    'output_files may contain paths only.');
summary = readtable(artifact.output_files.summary_csv);
assert(height(summary)==expected_csv_rows);
end

function remove_output(output)
if isfolder(output), rmdir(output,'s'); end
end
