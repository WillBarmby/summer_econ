function verify_ir_baseline(expected_file, tolerance)
%% VERIFY_IR_BASELINE Compare current IR output against a saved baseline.
%
% This is the succeed/fail check for refactoring. It reruns the current
% impulse-response generator using the seed and draw count stored in the
% expected artifact, then compares raw learning and RE IR cells.

if nargin < 1
    expected_file = 'baseline_ir_smoke_artifacts.mat';
end

if nargin < 2
    tolerance = 1e-10;
end

model_dir = fileparts(mfilename('fullpath'));
old_dir = pwd;
cleanup = onCleanup(@() cd(old_dir));

cd(model_dir);

expected_path = fullfile(model_dir, expected_file);
expected = load(expected_path, 'imp_resp_vec_L', 'imp_resp_vec_R', 'summary');

actual_file = 'baseline_ir_verify_tmp.mat';
run_ir_baseline_artifacts(expected.summary.seed_learning, ...
    expected.summary.n_draws, actual_file);
actual = load(fullfile(model_dir, actual_file), ...
    'imp_resp_vec_L', 'imp_resp_vec_R', 'summary');
delete(fullfile(model_dir, actual_file));

compare_summary(expected.summary.learning, actual.summary.learning, ...
    'learning');
compare_summary(expected.summary.rational_expectations, ...
    actual.summary.rational_expectations, 'rational expectations');

compare_ir_cells(expected.imp_resp_vec_L, actual.imp_resp_vec_L, ...
    tolerance, 'learning');
compare_ir_cells(expected.imp_resp_vec_R, actual.imp_resp_vec_R, ...
    tolerance, 'rational expectations');

fprintf('IR baseline verification passed: %s\n', expected_file);

end

function compare_summary(expected, actual, label)

if expected.any_nan ~= actual.any_nan
    error('%s NaN flag changed.', label);
end

if expected.any_inf ~= actual.any_inf
    error('%s Inf flag changed.', label);
end

if expected.n_series ~= actual.n_series
    error('%s series count changed.', label);
end

for idx = 1:expected.n_series
    if ~isequal(expected.dimensions{idx}, actual.dimensions{idx})
        error('%s series %d dimensions changed.', label, idx);
    end
end

end

function compare_ir_cells(expected, actual, tolerance, label)

if numel(expected) ~= numel(actual)
    error('%s IR cell count changed.', label);
end

for idx = 1:numel(expected)
    diff = max(abs(expected{idx}(:) - actual{idx}(:)));
    if diff > tolerance
        error('%s IR series %d changed: max abs diff %.16g > %.16g.', ...
            label, idx, diff, tolerance);
    end
end

end
