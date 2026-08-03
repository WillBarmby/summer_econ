function files = save_ep_gain_heatmap(sensitivity,output_dir)
%% SAVE_EP_GAIN_HEATMAP Save EE/IH amplification and status heatmaps.
% Each economic variable receives its own color scale. This prevents naturally
% volatile investment responses from visually erasing smaller output or hours
% effects. Numeric cell labels preserve exact values used in the figure.

gains = sensitivity.gains;
quantity_count = numel(sensitivity.quantity_names);
wedges = sensitivity.summary.maximum_absolute_median_learning_minus_re_wedge;
completion = 100*sensitivity.summary.completion_rate;
failure = 100*sensitivity.summary.failure_rate;

mat_path = fullfile(output_dir,'ep_gain_sensitivity.mat');
pdf_path = fullfile(output_dir,'ep_gain_sensitivity_heatmap.pdf');
png_path = fullfile(output_dir,'ep_gain_sensitivity_heatmap.png');
summary_csv = fullfile(output_dir,'ep_gain_sensitivity_summary.csv');
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
    'summary_csv',summary_csv);
write_gain_summary_csv(sensitivity.summary,summary_csv);
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
