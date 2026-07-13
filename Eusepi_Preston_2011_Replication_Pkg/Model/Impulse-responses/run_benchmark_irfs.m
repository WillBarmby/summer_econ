function artifact = run_benchmark_irfs(config, plot_spec, output_dir)
%% RUN_BENCHMARK_IRFS Generate, save, and plot the learning/RE benchmark.

if nargin ~= 3
    error('IRBenchmark:RequiredArguments', ...
        'config, plot_spec, and output_dir are all required.');
end
setup_ir_paths();
validate_ir_config(config);
validate_plot_spec(plot_spec,config.main.impulse_horizon-1);
if ~(ischar(output_dir) || (isstring(output_dir) && isscalar(output_dir)))
    error('IRBenchmark:InvalidOutputDirectory','output_dir must be text.');
end
if ~isfolder(output_dir), mkdir(output_dir); end

run_config = config;
run_config.main.store_output = false;

rng(config.baseline_seed,'twister');
run_config.main.learning = true;
[learning_raw,~,~,~,learning_draws] = run_impulse_responses(run_config);

rng(config.baseline_seed+1,'twister');
run_config.main.learning = false;
[re_raw,~,~,~,re_draws] = run_impulse_responses(run_config);

learning_status = summarize_statuses(learning_draws);
re_status = summarize_statuses(re_draws);
plot_spec.status.learning_completed = learning_status.completed;
plot_spec.status.re_completed = re_status.completed;
learning_raw = append_expected_sums(learning_raw,learning_draws, ...
    config.main.impulse_horizon-1);
re_raw = append_expected_sums(re_raw,re_draws,config.main.impulse_horizon-1);
plot_data = build_benchmark_plot_data(learning_raw,re_raw,learning_draws,re_draws,plot_spec);
figure_files = render_benchmark_figures(plot_data,plot_spec,output_dir);

artifact = struct('config',config,'plot_spec',plot_spec, ...
    'learning_raw',{learning_raw},'re_raw',{re_raw}, ...
    'learning_draws',{learning_draws},'re_draws',{re_draws}, ...
    'learning_status',learning_status,'re_status',re_status, ...
    'plot_data',plot_data,'figure_files',{figure_files});
save(fullfile(output_dir,'benchmark_irf_results.mat'),'-struct','artifact','-v7.3');
end

function values = append_expected_sums(values,draws,horizon)
first_index = numel(values)+1;
values{first_index} = NaN(numel(draws),horizon);
values{first_index+1} = NaN(numel(draws),horizon);
for draw_index = 1:numel(draws)
    if draws{draw_index}.status=="completed"
        values{first_index}(draw_index,:) = draws{draw_index}.expected_sums(1,:);
        values{first_index+1}(draw_index,:) = draws{draw_index}.expected_sums(2,:);
    end
end
end

function summary = summarize_statuses(draws)
statuses = cellfun(@(draw) string(draw.status),draws);
completed = statuses=="completed";
explosive = contains(statuses,"explosive");
invalid = contains(statuses,"invalid");
summary = struct('total',numel(draws),'completed',sum(completed), ...
    'explosive',sum(explosive),'invalid',sum(invalid), ...
    'other',sum(~(completed|explosive|invalid)),'statuses',statuses);
end

function data = build_benchmark_plot_data(learning,re,learning_draws,re_draws,spec)
learning_completed = cellfun(@(draw) draw.status=="completed",learning_draws);
re_completed = cellfun(@(draw) draw.status=="completed",re_draws);
if ~any(learning_completed) || ~any(re_completed)
    error('IRBenchmark:NoCompletedDraws', ...
        'At least one completed learning and RE draw is required for plotting.');
end

series_count = numel(learning);
data = repmat(struct('learning_median',[],'re_median',[], ...
    'learning_low',[],'learning_high',[]),series_count,1);
for series_index = 1:series_count
    learning_values = learning{series_index}(learning_completed,:);
    re_values = re{series_index}(re_completed,:);
    sorted = sort(learning_values,1);
    low_index = max(1,ceil(spec.band_probabilities(1)*size(sorted,1)));
    high_index = min(size(sorted,1),ceil(spec.band_probabilities(2)*size(sorted,1)));
    data(series_index).learning_median = median(learning_values,1);
    data(series_index).re_median = median(re_values,1);
    data(series_index).learning_low = sorted(low_index,:);
    data(series_index).learning_high = sorted(high_index,:);
end
end

function files = render_benchmark_figures(data,spec,output_dir)
files = {};
for figure_index = 1:numel(spec.figures)
    definition = spec.figures(figure_index);
    figure_handle = figure('Visible',spec.visible,'Color','white', ...
        'Position',[100 100 spec.figure_size]);
    cleanup = onCleanup(@() close(figure_handle));
    layout = tiledlayout(figure_handle,definition.layout(1),definition.layout(2), ...
        'TileSpacing','compact','Padding','compact');
    for panel_index = 1:numel(definition.panels)
        panel = definition.panels(panel_index);
        axis_handle = nexttile(layout);
        render_panel(axis_handle,data,panel,spec);
    end
    title(layout,sprintf('%s | completed draws: learning %d, RE %d', ...
        definition.title,spec.status.learning_completed,spec.status.re_completed), ...
        'Interpreter','none');
    pdf_path = fullfile(output_dir,[definition.file_stem '.pdf']);
    png_path = fullfile(output_dir,[definition.file_stem '.png']);
    exportgraphics(figure_handle,pdf_path,'ContentType','vector');
    exportgraphics(figure_handle,png_path,'Resolution',spec.png_resolution);
    files(end+1:end+2) = {pdf_path,png_path}; %#ok<AGROW>
    clear cleanup
end
end

function render_panel(axis_handle,data,panel,spec)
periods = spec.periods;
if panel.kind == "learning_minus_re"
    left = data(panel.series_index).learning_median(periods);
    right = data(panel.comparison_series_index).learning_median(periods)- ...
        data(panel.comparison_series_index).re_median(periods);
    plot(axis_handle,periods,left,spec.styles.learning,periods,right,spec.styles.re, ...
        'LineWidth',spec.line_width);
    legend(axis_handle,{'Forecast error','Learning minus RE output'},'Location','best');
else
    values = data(panel.series_index);
    plot(axis_handle,periods,values.learning_median(periods),spec.styles.learning, ...
        periods,values.re_median(periods),spec.styles.re, ...
        periods,values.learning_low(periods),spec.styles.band, ...
        periods,values.learning_high(periods),spec.styles.band, ...
        'LineWidth',spec.line_width);
    legend(axis_handle,{'Learning','RE','15th percentile','85th percentile'}, ...
        'Location','best');
end
title(axis_handle,panel.title,'Interpreter','none');
xlabel(axis_handle,'Quarters'); ylabel(axis_handle,'% deviation');
grid(axis_handle,'on'); xlim(axis_handle,[periods(1) periods(end)]);
if ~isempty(panel.y_limits), ylim(axis_handle,panel.y_limits); end
end

function validate_plot_spec(spec,max_period)
required = {'periods','band_probabilities','visible','figure_size', ...
    'png_resolution','line_width','styles','figures','status'};
if ~isstruct(spec) || ~isscalar(spec) || ~isempty(setxor(fieldnames(spec),required.'))
    error('IRBenchmark:InvalidPlotSpec','A complete plot specification is required.');
end
if any(spec.periods<1) || any(spec.periods>max_period) || ...
        any(spec.periods~=floor(spec.periods))
    error('IRBenchmark:InvalidPlotSpec','Plot periods are outside the simulated horizon.');
end
if ~isequal(size(spec.band_probabilities),[1 2]) || ...
        any(spec.band_probabilities<=0) || any(spec.band_probabilities>=1) || ...
        spec.band_probabilities(1)>=spec.band_probabilities(2)
    error('IRBenchmark:InvalidPlotSpec','band_probabilities must be increasing values in (0,1).');
end
end
