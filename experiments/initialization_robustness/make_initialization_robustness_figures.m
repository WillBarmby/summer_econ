function files = make_initialization_robustness_figures(artifact,output_dir)
%% MAKE_INITIALIZATION_ROBUSTNESS_FIGURES Create main and appendix panels.
% Main panels use the standard 2,000-observation training period. The appendix
% panel shows the draw-first treatment effect over all nested training horizons.

stem = fullfile(output_dir,'initialization_robustness');
files = struct('irf_pdf',[stem '_irfs.pdf'],'irf_png',[stem '_irfs.png'], ...
    'difference_pdf',[stem '_differences.pdf'], ...
    'difference_png',[stem '_differences.png'], ...
    'summary_pdf',[stem '_summary.pdf'],'summary_png',[stem '_summary.png'], ...
    'appendix_pdf',[stem '_training_horizons.pdf'], ...
    'appendix_png',[stem '_training_horizons.png']);
standard = find(artifact.training_horizons==2000,1);
assert(~isempty(standard),'EPResearch:InitializationDesign', ...
    'The main figure requires the standard 2,000-period treatment.');
plot_treatment_irfs(artifact,standard,files);
plot_differences(artifact,standard,files);
plot_summary(artifact,standard,files);
plot_training_horizons(artifact,files);
end

function plot_treatment_irfs(artifact,j,files)
fig = figure('Visible','off','Color','white','Position',[30 30 1500 1000]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
for s = 1:3
    for q = 1:4
        ax = nexttile(layout); hold(ax,'on'); yline(ax,0,':');
        handles = gobjects(1,2);
        for treatment = 1:2
            values = squeeze(median(artifact.metrics.learning_minus_re_irf( ...
                :,s,treatment,j,q,:),1,'omitnan'));
            style = '-'; if treatment==2, style = '--'; end
            handles(treatment) = plot(ax,1:numel(values),values,style, ...
                'LineWidth',1.6);
        end
        grid(ax,'on'); title(ax,artifact.quantity_names{q});
        if q==1, ylabel(ax,artifact.specification_labels{s}); end
        if s==3, xlabel(ax,'Periods after impulse'); end
        if s==1 && q==1
            legend(ax,handles,{'RE initialization','Half-RE initialization'}, ...
                'Location','best');
        end
    end
end
title(layout,'Learning-minus-RE responses after 2,000 training observations');
exportgraphics(fig,files.irf_pdf,'ContentType','vector');
exportgraphics(fig,files.irf_png,'Resolution',250);
clear cleanup
end

function plot_differences(artifact,j,files)
fig = figure('Visible','off','Color','white','Position',[30 30 1500 1000]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
for s = 1:3
    usable = artifact.metrics.joint_completion(:,s,j);
    for q = 1:4
        ax = nexttile(layout); hold(ax,'on');
        values = squeeze(artifact.metrics.initialization_difference_irf( ...
            usable,s,j,q,:));
        ordered = sort(values,1);
        n = size(ordered,1);
        low = ordered(max(1,ceil(0.25*n)),:);
        high = ordered(min(n,ceil(0.75*n)),:);
        middle = median(values,1);
        periods = 1:size(values,2);
        fill(ax,[periods fliplr(periods)],[low fliplr(high)], ...
            [0.82 0.88 0.96],'EdgeColor','none');
        plot(ax,periods,middle,'Color',[0 0.35 0.7],'LineWidth',1.6);
        yline(ax,0,':'); grid(ax,'on'); title(ax,artifact.quantity_names{q});
        if q==1, ylabel(ax,[artifact.specification_labels{s} newline ...
                'Half-RE minus RE-init']); end
        if s==3, xlabel(ax,'Periods after impulse'); end
    end
end
title(layout,'Paired initialization effect after 2,000 observations');
exportgraphics(fig,files.difference_pdf,'ContentType','vector');
exportgraphics(fig,files.difference_png,'Resolution',250);
clear cleanup
end

function plot_summary(artifact,j,files)
fig = figure('Visible','off','Color','white','Position',[30 30 1450 500]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
render_heatmap(nexttile(layout), ...
    squeeze(artifact.metrics.relative_initialization_effect(:,j,:)), ...
    artifact,'Initialization effect / learning effect','%.2f');
ax = nexttile(layout);
bar(ax,median(artifact.metrics.retained_initial_displacement(:,:,j),1,'omitnan'));
grid(ax,'on'); xticklabels(ax,artifact.specification_labels);
ylabel(ax,'Fraction'); title(ax,'Median initial displacement retained');
ax = nexttile(layout);
completion = 100*squeeze(artifact.metrics.rates(:,:,j,1));
bar(ax,completion); ylim(ax,[0 105]); grid(ax,'on');
xticklabels(ax,artifact.specification_labels); ylabel(ax,'Percent');
title(ax,'Completed paths'); legend(ax,{'RE','Half-RE'},'Location','best');
title(layout,'Initialization robustness after 2,000 observations');
exportgraphics(fig,files.summary_pdf,'ContentType','vector');
exportgraphics(fig,files.summary_png,'Resolution',250);
clear cleanup
end

function plot_training_horizons(artifact,files)
fig = figure('Visible','off','Color','white','Position',[30 30 1500 1000]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
for s = 1:3
    for q = 1:4
        ax = nexttile(layout);
        plot(ax,artifact.training_horizons,squeeze( ...
            artifact.metrics.median_max_initialization_effect(s,:,q)), ...
            'o-','LineWidth',1.6);
        grid(ax,'on'); title(ax,artifact.quantity_names{q});
        if q==1
            ylabel(ax,[artifact.specification_labels{s} newline ...
                'Median draw max |Half-RE - RE-init|']);
        end
        if s==3, xlabel(ax,'Training observations'); end
    end
end
title(layout,'Appendix: initialization effect over nested training horizons');
exportgraphics(fig,files.appendix_pdf,'ContentType','vector');
exportgraphics(fig,files.appendix_png,'Resolution',250);
clear cleanup
end

function render_heatmap(ax,values,artifact,heading,format)
imagesc(ax,values); colorbar(ax); colormap(ax,parula);
xticks(ax,1:4); xticklabels(ax,artifact.quantity_names);
yticks(ax,1:3); yticklabels(ax,artifact.specification_labels);
title(ax,heading);
for row = 1:size(values,1)
    for column = 1:size(values,2)
        text(ax,column,row,sprintf(format,values(row,column)), ...
            'HorizontalAlignment','center','FontWeight','bold');
    end
end
end
