function files = save_ep_artifact_and_panels(artifact,output_dir)
%% SAVE_EP_ARTIFACT_AND_PANELS Save one artifact and common EE/IH panels.

if ~isfolder(output_dir), mkdir(output_dir); end
mat_path = fullfile(output_dir,[artifact.experiment '.mat']);
pdf_path = fullfile(output_dir,[artifact.experiment '_panels.pdf']);
png_path = fullfile(output_dir,[artifact.experiment '_panels.png']);
fig = figure('Visible','off','Color','white','Position',[50 50 1400 650]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,4,'TileSpacing','compact','Padding','compact');
periods = artifact.config.plot_periods;
for row = 1:2
    result = artifact.results{row};
    for column = 1:4
        ax = nexttile(layout);
        render_response(ax,result.summary,column,periods);
        title(ax,sprintf('%s — %s',result.label, ...
            artifact.quantity_names{column}),'Interpreter','none');
        ylabel(ax,'Percent deviation');
    end
end
legend(nexttile(layout,1),{'25th–75th percentile','Learning median','RE'}, ...
    'Location','best');
title(layout,'E&P response to a one-percentage-point technology-growth shock');
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path);
save(mat_path,'-struct','artifact','-v7.3');
clear cleanup
end

function render_response(ax,summary,row,periods)
fill(ax,[periods fliplr(periods)], ...
    [summary.learning_low(row,periods) ...
    fliplr(summary.learning_high(row,periods))],[0.85 0.85 0.85], ...
    'EdgeColor','none');
hold(ax,'on');
plot(ax,periods,summary.learning_median(row,periods),'k-','LineWidth',1.5);
plot(ax,periods,summary.re(row,periods),'k--','LineWidth',1.5);
yline(ax,0,'Color',[0.65 0.65 0.65]);
xlabel(ax,'Quarters');
xlim(ax,[periods(1) periods(end)]);
grid(ax,'on');
end
