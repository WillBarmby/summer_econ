function files = save_ep_growth_panels(growth,output_dir)
%% SAVE_EP_GROWTH_PANELS Plot gamma_bar=1 minus original-growth responses.

pdf_path = fullfile(output_dir,'ep_growth_sensitivity_panels.pdf');
png_path = fullfile(output_dir,'ep_growth_sensitivity_panels.png');
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
files = struct('pdf',pdf_path,'png',png_path);
clear cleanup
end
