function files = save_initialization_robustness(artifact,output_dir)
%% SAVE_INITIALIZATION_ROBUSTNESS Write the common artifact's paper outputs.

stem = fullfile(output_dir,'initialization_robustness');
files = struct('mat',[stem '.mat'],'summary_csv',[stem '_summary.csv'], ...
    'irf_pdf',[stem '_irfs.pdf'],'irf_png',[stem '_irfs.png'], ...
    'difference_pdf',[stem '_differences.pdf'], ...
    'difference_png',[stem '_differences.png'], ...
    'summary_pdf',[stem '_summary.pdf'], ...
    'summary_png',[stem '_summary.png']);
write_summary(artifact,files.summary_csv);
plot_treatment_irfs(artifact,files);
plot_differences(artifact,files);
plot_summary(artifact,files);
end

function write_summary(artifact,path)
S = numel(artifact.specification_ids);
Q = numel(artifact.quantity_names);
specification = strings(S*Q,1);
quantity = strings(S*Q,1);
initialization_effect = NaN(S*Q,1);
learning_effect = NaN(S*Q,1);
relative_effect = NaN(S*Q,1);
completion_re = NaN(S*Q,1);
completion_half_re = NaN(S*Q,1);
joint_completion = NaN(S*Q,1);
median_displacement_retained = NaN(S*Q,1);
projection_rate_re = NaN(S*Q,1);
projection_rate_half_re = NaN(S*Q,1);
row = 0;
for s = 1:S
    for q = 1:Q
        row = row+1;
        specification(row) = artifact.specification_ids(s);
        quantity(row) = artifact.quantity_names{q};
        initialization_effect(row) = ...
            artifact.metrics.median_max_initialization_effect(s,q);
        learning_effect(row) = artifact.metrics.median_max_learning_effect(s,q);
        relative_effect(row) = artifact.metrics.relative_initialization_effect(s,q);
        completion_re(row) = artifact.metrics.rates(s,1,1);
        completion_half_re(row) = artifact.metrics.rates(s,2,1);
        joint_completion(row) = artifact.metrics.joint_completion_rate(s);
        median_displacement_retained(row) = median( ...
            artifact.metrics.retained_initial_displacement(:,s),'omitnan');
        projection_rate_re(row) = artifact.metrics.projection_event_rate(s,1);
        projection_rate_half_re(row) = artifact.metrics.projection_event_rate(s,2);
    end
end
writetable(table(specification,quantity,initialization_effect, ...
    learning_effect,relative_effect,completion_re,completion_half_re, ...
    joint_completion,median_displacement_retained,projection_rate_re, ...
    projection_rate_half_re),path);
end

function plot_treatment_irfs(artifact,files)
fig = figure('Visible','off','Color','white','Position',[30 30 1500 1000]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
for s = 1:3
    for q = 1:4
        ax = nexttile(layout); hold(ax,'on'); yline(ax,0,':');
        handles = gobjects(1,2);
        for treatment = 1:2
            values = squeeze(median(artifact.metrics.learning_minus_re_irf( ...
                :,s,treatment,q,:),1,'omitnan'));
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
title(layout,'Conditional learning-minus-RE responses');
exportgraphics(fig,files.irf_pdf,'ContentType','vector');
exportgraphics(fig,files.irf_png,'Resolution',250);
clear cleanup
end

function plot_differences(artifact,files)
fig = figure('Visible','off','Color','white','Position',[30 30 1500 1000]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
for s = 1:3
    usable = artifact.metrics.joint_completion(:,s);
    for q = 1:4
        ax = nexttile(layout); hold(ax,'on');
        values = squeeze(artifact.metrics.initialization_difference_irf( ...
            usable,s,q,:));
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
title(layout,'Paired initialization effect: median and interquartile band');
exportgraphics(fig,files.difference_pdf,'ContentType','vector');
exportgraphics(fig,files.difference_png,'Resolution',250);
clear cleanup
end

function plot_summary(artifact,files)
fig = figure('Visible','off','Color','white','Position',[30 30 1450 500]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
render_heatmap(nexttile(layout),artifact.metrics.relative_initialization_effect, ...
    artifact,'Initialization effect / learning effect','%.2f');
ax = nexttile(layout);
bar(ax,median(artifact.metrics.retained_initial_displacement,1,'omitnan'));
grid(ax,'on'); xticklabels(ax,artifact.specification_labels);
ylabel(ax,'Fraction'); title(ax,'Median initial displacement retained');
ax = nexttile(layout);
completion = 100*squeeze(artifact.metrics.rates(:,:,1));
bar(ax,completion); ylim(ax,[0 105]); grid(ax,'on');
xticklabels(ax,artifact.specification_labels); ylabel(ax,'Percent');
title(ax,'Completed paths'); legend(ax,{'RE','Half-RE'},'Location','best');
title(layout,'Harmonized initialization robustness summary');
exportgraphics(fig,files.summary_pdf,'ContentType','vector');
exportgraphics(fig,files.summary_png,'Resolution',250);
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
