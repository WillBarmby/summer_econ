function plot_data = render_ir_comparison(legacy_result, new_result, plot_spec, output_dir)
%% RENDER_IR_COMPARISON Render legacy and explicit results with one plot specification.

required = {'series_indices','series_titles','periods','visible','line_width'};
if ~isstruct(plot_spec) || ~isempty(setxor(fieldnames(plot_spec),required.'))
    error('IRPlot:InvalidSpecification','A complete plot specification is required.');
end
if numel(plot_spec.series_indices) ~= numel(plot_spec.series_titles)
    error('IRPlot:InvalidSpecification','Every plotted series requires a title.');
end
if ~(ischar(output_dir) || (isstring(output_dir) && isscalar(output_dir)))
    error('IRPlot:InvalidOutputDirectory','output_dir must be text.');
end
if ~isfolder(output_dir), mkdir(output_dir); end

plot_data = struct();
plot_data.legacy = extract_plot_data(legacy_result,plot_spec);
plot_data.new = extract_plot_data(new_result,plot_spec);
render_one(plot_data.legacy,plot_spec,fullfile(output_dir,'legacy_irf.pdf'));
render_one(plot_data.new,plot_spec,fullfile(output_dir,'explicit_irf.pdf'));
end

function data = extract_plot_data(result,spec)
data = repmat(struct('median',[],'low',[],'up',[]),numel(spec.series_indices),1);
for j = 1:numel(spec.series_indices)
    index = spec.series_indices(j);
    data(j).median = result.median_imp_resp_vec{index}(spec.periods);
    data(j).low = result.low_band{index}(spec.periods);
    data(j).up = result.up_band{index}(spec.periods);
end
end

function render_one(data,spec,path)
figure_handle = figure('Visible',spec.visible,'Color','white');
cleanup = onCleanup(@() close(figure_handle));
layout = tiledlayout(figure_handle,ceil(numel(data)/2),2, ...
    'TileSpacing','compact','Padding','compact');
for j = 1:numel(data)
    axis_handle = nexttile(layout);
    plot(axis_handle,spec.periods,data(j).median,'k-', ...
        spec.periods,data(j).low,'k:',spec.periods,data(j).up,'k:', ...
        'LineWidth',spec.line_width);
    title(axis_handle,spec.series_titles{j},'Interpreter','none');
    xlabel(axis_handle,'Quarters');
    ylabel(axis_handle,'% deviation');
    grid(axis_handle,'on');
end
exportgraphics(figure_handle,path,'ContentType','vector');
end
