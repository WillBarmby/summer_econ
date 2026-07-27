function files = save_ep_gain_heatmap(sensitivity,output_dir)
%% SAVE_EP_GAIN_HEATMAP Save EE/IH amplification and status heatmaps.
% Each economic variable receives its own color scale. This prevents naturally
% volatile investment responses from visually erasing smaller output or hours
% effects. Numeric cell labels preserve exact values used in the figure.

gains = sensitivity.gains;
periods = sensitivity.config.plot_periods;
results = {sensitivity.ee_results,sensitivity.ih_results};
specification_count = numel(results);
gain_count = numel(gains);
quantity_count = numel(sensitivity.quantity_names);
wedges = NaN(specification_count,gain_count,quantity_count);
completion = NaN(specification_count,gain_count);
failure = NaN(specification_count,gain_count);
for row = 1:specification_count
    for column = 1:gain_count
        result = results{row}{column};
        difference = result.summary.learning_median(:,periods)- ...
            result.summary.re(:,periods);
        wedges(row,column,:) = max(abs(difference),[],2,'omitnan');
        draw_count = numel(result.statuses);
        completion(row,column) = 100*result.status_counts.completed/draw_count;
        failure(row,column) = 100*(result.status_counts.explosive+ ...
            result.status_counts.invalid)/draw_count;
    end
end

mat_path = fullfile(output_dir,'ep_gain_sensitivity.mat');
pdf_path = fullfile(output_dir,'ep_gain_sensitivity_heatmap.pdf');
png_path = fullfile(output_dir,'ep_gain_sensitivity_heatmap.png');
fig = figure('Visible','off','Color','white','Position',[50 50 1500 760]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for quantity = 1:quantity_count
    ax = nexttile(layout);
    render_heatmap(ax,squeeze(wedges(:,:,quantity)),gains, ...
        sensitivity.specification_names,'%.3f');
    title(ax,sensitivity.quantity_names{quantity});
    colorbar(ax);
end
ax = nexttile(layout);
render_heatmap(ax,completion,gains,sensitivity.specification_names,'%.0f');
title(ax,'Completed draws (%)'); colorbar(ax);
ax = nexttile(layout);
render_heatmap(ax,failure,gains,sensitivity.specification_names,'%.0f');
title(ax,'Invalid or explosive draws (%)'); colorbar(ax);
title(layout,['E&P gain sensitivity: maximum absolute median ' ...
    'learning-minus-RE response']);
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path, ...
    'wedge_metric',wedges,'completion_percent',completion, ...
    'failure_percent',failure);
save(mat_path,'-struct','sensitivity','-v7.3');
clear cleanup
end

function render_heatmap(ax,values,gains,row_names,number_format)
imagesc(ax,values);
colormap(ax,parula);
xticks(ax,1:numel(gains));
xticklabels(ax,arrayfun(@(x) sprintf('%g',x),gains,'UniformOutput',false));
yticks(ax,1:numel(row_names)); yticklabels(ax,row_names);
xlabel(ax,'Constant gain');
for row = 1:size(values,1)
    for column = 1:size(values,2)
        text(ax,column,row,sprintf(number_format,values(row,column)), ...
            'HorizontalAlignment','center','FontWeight','bold','Color','black');
    end
end
end
