function files = save_gain_comparison_heatmap(comparison,output_dir)
%% SAVE_GAIN_COMPARISON_HEATMAP Save the common-shock three-specification map.

quantities = numel(comparison.quantity_names);
wedges = comparison.summary.maximum_absolute_median_learning_minus_re_wedge;
completion = 100*comparison.summary.completion_rate;
failure = 100*comparison.summary.failure_rate;

mat_path = fullfile(output_dir,'gain_sensitivity_comparison.mat');
pdf_path = fullfile(output_dir,'gain_sensitivity_comparison_heatmap.pdf');
png_path = fullfile(output_dir,'gain_sensitivity_comparison_heatmap.png');
summary_csv = fullfile(output_dir,'gain_sensitivity_comparison_summary.csv');
fig = figure('Visible','off','Color','white','Position',[50 50 1500 840]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for quantity = 1:quantities
    ax = nexttile(layout);
    render_map(ax,squeeze(wedges(:,:,quantity)),comparison,'%.3f');
    title(ax,comparison.quantity_names{quantity}); colorbar(ax);
end
ax = nexttile(layout);
render_map(ax,completion,comparison,'%.0f');
title(ax,'Completed draws (%)'); colorbar(ax);
ax = nexttile(layout);
render_map(ax,failure,comparison,'%.0f');
title(ax,'Invalid or explosive draws (%)'); colorbar(ax);
title(layout,['Common technology shock: maximum absolute median ' ...
    'learning-minus-RE response']);
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path, ...
    'summary_csv',summary_csv);
write_gain_summary_csv(comparison.summary,summary_csv);
save(mat_path,'-struct','comparison','-v7.3');
clear cleanup
end

function render_map(ax,values,comparison,number_format)
imagesc(ax,values); colormap(ax,parula);
xticks(ax,1:numel(comparison.gains));
xticklabels(ax,arrayfun(@(x) sprintf('%g',x),comparison.gains, ...
    'UniformOutput',false));
yticks(ax,1:numel(comparison.specification_names));
yticklabels(ax,comparison.specification_names);
xlabel(ax,'Constant gain');
for row = 1:size(values,1)
    for column = 1:size(values,2)
        text(ax,column,row,sprintf(number_format,values(row,column)), ...
            'HorizontalAlignment','center','FontWeight','bold','Color','black');
    end
end
end
