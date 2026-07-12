function run_ir_baseline_artifacts(seed, n_draws, output_file)
%% RUN_IR_BASELINE_ARTIFACTS Generate deterministic IR baseline artifacts.
%
% This is a characterization harness for the legacy impulse-response code.
% It runs Main_imp_resp_Sept_2009.m for learning and rational expectations
% with fixed RNG seeds, then saves raw IR cells and compact diagnostics.

if nargin < 1
    seed = 20260701;
end

if nargin < 2
    n_draws = 100;
end

if nargin < 3
    output_file = 'baseline_ir_artifacts.mat';
end

model_dir = setup_ir_paths();
config = make_ir_config();
config.main.n_draws = n_draws;
config.main.store_output = false;

%% Learning case
rng(seed, 'twister');
config.main.learning = true;
[imp_resp_vec_L,~,~,~,learning_draws] = run_impulse_responses(config);
summary_L = summarize_ir_cells(imp_resp_vec_L);

%% Rational expectations case
rng(seed + 1, 'twister');
config.main.learning = false;
[imp_resp_vec_R,~,~,~,re_draws] = run_impulse_responses(config);
summary_R = summarize_ir_cells(imp_resp_vec_R);

summary = struct();
summary.created_at = char(datetime('now'));
summary.seed_learning = seed;
summary.seed_rational_expectations = seed + 1;
summary.n_draws = n_draws;
summary.learning = summary_L;
summary.rational_expectations = summary_R;

save(fullfile(model_dir, output_file), ...
    'imp_resp_vec_L', 'imp_resp_vec_R', 'learning_draws', 're_draws', ...
    'summary', '-v7.3');

end

function summary = summarize_ir_cells(imp_resp_vec)

n_series = numel(imp_resp_vec);
selected_series = 1:n_series;
selected_periods = [1 2 5 10 20 40 63];

summary = struct();
summary.n_series = n_series;
summary.dimensions = cell(n_series, 1);
summary.has_nan = false(n_series, 1);
summary.has_inf = false(n_series, 1);
summary.medians = cell(n_series, 1);
summary.selected_series = selected_series;
summary.selected_periods = selected_periods;
summary.selected_values = cell(n_series, 1);

for idx = 1:n_series
    values = imp_resp_vec{idx};
    summary.dimensions{idx} = size(values);
    summary.has_nan(idx) = any(isnan(values(:)));
    summary.has_inf(idx) = any(isinf(values(:)));
    summary.medians{idx} = median(values, 1);

    valid_periods = selected_periods(selected_periods <= size(values, 2));
    selected = struct();
    selected.periods = valid_periods;
    selected.first_draw = values(1, valid_periods);
    selected.median = summary.medians{idx}(valid_periods);
    selected.mean = mean(values(:, valid_periods), 1);
    summary.selected_values{idx} = selected;
end

summary.any_nan = any(summary.has_nan);
summary.any_inf = any(summary.has_inf);

end
