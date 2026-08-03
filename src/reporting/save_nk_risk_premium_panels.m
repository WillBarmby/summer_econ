function files = save_nk_risk_premium_panels(result,output_dir)
%% SAVE_NK_RISK_PREMIUM_PANELS Save NK EE distribution and RE comparison.

mat_path = fullfile(output_dir,'nk_risk_premium_comparison.mat');
pdf_path = fullfile(output_dir,'nk_risk_premium_panels.pdf');
png_path = fullfile(output_dir,'nk_risk_premium_panels.png');
summary_csv = fullfile(output_dir,'nk_risk_premium_comparison_summary.csv');
fig = figure('Visible','off','Color','white','Position',[50 50 1400 720]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
periods = result.config.plot_periods;
summary = result.simulation.summary;
for quantity = 1:6
    ax = nexttile(layout);
    fill(ax,[periods fliplr(periods)], ...
        [summary.learning_low(quantity,periods) ...
        fliplr(summary.learning_high(quantity,periods))],[0.88 0.84 0.93], ...
        'EdgeColor','none');
    hold(ax,'on');
    plot(ax,periods,summary.learning_median(quantity,periods), ...
        'Color',[0.50 0.18 0.62],'LineWidth',1.5);
    plot(ax,periods,summary.re(quantity,periods),'k--','LineWidth',1.4);
    yline(ax,0,'Color',[0.7 0.7 0.7]);
    title(ax,result.quantity_names{quantity});
    xlabel(ax,'Quarters'); ylabel(ax,'Percent deviation');
    xlim(ax,[periods(1) periods(end)]); grid(ax,'on');
end
legend(nexttile(layout,1),{'25th–75th percentile','NK EE median','NK RE'}, ...
    'Location','best');
title(layout,'NK response to a one-percentage-point i.i.d. risk-premium shock');
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path, ...
    'summary_csv',summary_csv);
write_learning_summary_csv(result.summary,summary_csv);
save(mat_path,'-struct','result','-v7.3');
clear cleanup
end
