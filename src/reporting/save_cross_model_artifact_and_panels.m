function files = save_cross_model_artifact_and_panels(comparison,output_dir)
%% SAVE_CROSS_MODEL_ARTIFACT_AND_PANELS Save overlay and learning-wedge panels.
% Confidence bands are omitted from the five-line overlay because three sets
% of bands would obscure the comparison. The complete draw distributions remain
% in the MAT artifact and the standalone E&P panels retain their bands.

if ~isfolder(output_dir), mkdir(output_dir); end
mat_path = fullfile(output_dir,'cross_model_comparison.mat');
overlay_pdf = fullfile(output_dir,'cross_model_overlay.pdf');
overlay_png = fullfile(output_dir,'cross_model_overlay.png');
wedge_pdf = fullfile(output_dir,'learning_wedges.pdf');
wedge_png = fullfile(output_dir,'learning_wedges.png');
periods = comparison.config.plot_periods;
ep_ee = comparison.ep_results{1};
ep_ih = comparison.ep_results{2};
nk_ee = comparison.nk_result;

%% Five-path headline comparison.
fig = figure('Visible','off','Color','white','Position',[50 50 1400 650]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for quantity = 1:4
    ax = nexttile(layout);
    plot(ax,periods,ep_ih.summary.re(quantity,periods),'k--','LineWidth',1.4);
    hold(ax,'on');
    plot(ax,periods,ep_ee.summary.learning_median(quantity,periods), ...
        'Color',[0.20 0.45 0.75],'LineWidth',1.5);
    plot(ax,periods,ep_ih.summary.learning_median(quantity,periods), ...
        'Color',[0.15 0.65 0.45],'LineWidth',1.5);
    plot(ax,periods,nk_ee.summary.re(quantity,periods), ...
        'Color',[0.75 0.25 0.20],'LineStyle','--','LineWidth',1.4);
    plot(ax,periods,nk_ee.summary.learning_median(quantity,periods), ...
        'Color',[0.55 0.20 0.65],'LineWidth',1.5);
    yline(ax,0,'Color',[0.7 0.7 0.7]);
    title(ax,comparison.quantity_names{quantity});
    xlabel(ax,'Quarters'); ylabel(ax,'Percent deviation');
    xlim(ax,[periods(1) periods(end)]); grid(ax,'on');
end
legend(nexttile(layout,1),{'E&P RE','E&P EE','E&P IH','NK RE','NK EE'}, ...
    'Location','best');
title(layout,'Common technology-growth shock: model and learning responses');
exportgraphics(fig,overlay_pdf,'ContentType','vector');
exportgraphics(fig,overlay_png,'Resolution',250);
clear cleanup

%% Within-model learning wedges.
fig = figure('Visible','off','Color','white','Position',[50 50 1400 650]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for quantity = 1:4
    ax = nexttile(layout);
    plot(ax,periods,ep_ee.summary.learning_median(quantity,periods)- ...
        ep_ee.summary.re(quantity,periods),'Color',[0.20 0.45 0.75], ...
        'LineWidth',1.5);
    hold(ax,'on');
    plot(ax,periods,ep_ih.summary.learning_median(quantity,periods)- ...
        ep_ih.summary.re(quantity,periods),'Color',[0.15 0.65 0.45], ...
        'LineWidth',1.5);
    plot(ax,periods,nk_ee.summary.learning_median(quantity,periods)- ...
        nk_ee.summary.re(quantity,periods),'Color',[0.55 0.20 0.65], ...
        'LineWidth',1.5);
    yline(ax,0,'Color',[0.7 0.7 0.7]);
    title(ax,comparison.quantity_names{quantity});
    xlabel(ax,'Quarters'); ylabel(ax,'Learning minus own RE');
    xlim(ax,[periods(1) periods(end)]); grid(ax,'on');
end
legend(nexttile(layout,1),{'E&P EE wedge','E&P IH wedge','NK EE wedge'}, ...
    'Location','best');
title(layout,'Within-model learning effects');
exportgraphics(fig,wedge_pdf,'ContentType','vector');
exportgraphics(fig,wedge_png,'Resolution',250);
clear cleanup

files = struct('mat',mat_path,'overlay_pdf',overlay_pdf, ...
    'overlay_png',overlay_png,'wedge_pdf',wedge_pdf,'wedge_png',wedge_png, ...
    'ep_artifact',fullfile(output_dir,'ep','ep_comparison.mat'));
save(mat_path,'-struct','comparison','-v7.3');
end
