function files = save_ep_growth_panels(growth,output_dir)
%% SAVE_EP_GROWTH_PANELS Plot gamma_bar=1 minus original-growth responses.

pdf_path = fullfile(output_dir,'ep_growth_sensitivity_panels.pdf');
png_path = fullfile(output_dir,'ep_growth_sensitivity_panels.png');
mat_path = fullfile(output_dir,'ep_growth_sensitivity.mat');
summary_csv = fullfile(output_dir,'ep_growth_sensitivity_summary.csv');
fig = figure('Visible','off','Color','white','Position',[50 50 1400 650]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,4,'TileSpacing','compact','Padding','compact');
periods = growth.config.plot_periods;
quantities = growth.baseline.quantity_names;
for row = 1:2
    difference = growth.differences{row};
    label = growth.baseline.specification_labels{row};
    for column = 1:4
        ax = nexttile(layout);
        plot(ax,periods,difference.learning_median(column,periods), ...
            'k-','LineWidth',1.5);
        hold(ax,'on');
        plot(ax,periods,difference.re(column,periods), ...
            'k--','LineWidth',1.5);
        yline(ax,0,'Color',[0.65 0.65 0.65]);
        title(ax,sprintf('%s — %s',label,quantities{column}), ...
            'Interpreter','none');
        xlabel(ax,'Quarters');
        ylabel(ax,'Percentage-point difference');
        xlim(ax,[periods(1) periods(end)]);
        grid(ax,'on');
    end
end
legend(nexttile(layout,1),{'Learning median','RE'},'Location','best');
title(layout,'E&P response: gamma_bar = 1 minus gamma_bar = exp(0.0053)');
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path, ...
    'summary_csv',summary_csv);
write_growth_summary(growth.summary,summary_csv);
clear cleanup
end

function write_growth_summary(summary,path)
S = numel(summary.specification_ids);
Q = numel(summary.quantity_names);
rows = S*Q;
specification = strings(rows,1);
quantity = strings(rows,1);
maximum_absolute_learning_median_difference = NaN(rows,1);
maximum_absolute_re_difference = NaN(rows,1);
original_growth_completion_rate = NaN(rows,1);
zero_growth_completion_rate = NaN(rows,1);
response_unit = repmat(string(summary.response_unit),rows,1);
first_horizon = repmat(summary.reported_horizons(1),rows,1);
last_horizon = repmat(summary.reported_horizons(end),rows,1);
row = 0;
for s = 1:S
    for q = 1:Q
        row = row+1;
        specification(row) = string(summary.specification_ids{s});
        quantity(row) = string(summary.quantity_names{q});
        maximum_absolute_learning_median_difference(row) = ...
            summary.maximum_absolute_learning_median_difference(s,q);
        maximum_absolute_re_difference(row) = ...
            summary.maximum_absolute_re_difference(s,q);
        original_growth_completion_rate(row) = summary.completion_rate(s,1);
        zero_growth_completion_rate(row) = summary.completion_rate(s,2);
    end
end
writetable(table(specification,quantity, ...
    maximum_absolute_learning_median_difference,maximum_absolute_re_difference, ...
    original_growth_completion_rate,zero_growth_completion_rate,response_unit, ...
    first_horizon,last_horizon),path);
end
