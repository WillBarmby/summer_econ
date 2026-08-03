function files = save_ep_ee_consumption_audit(artifact,output_dir)
%% SAVE_EP_EE_CONSUMPTION_AUDIT Save paired evidence and paper-ready figures.

results = artifact.results;
draws = artifact.config.draw_count;
quantities = numel(artifact.quantity_names);
periods = artifact.config.ir_periods;
rates = NaN(2,3);
projections = NaN(draws,2);
observations = NaN(draws,2);
wedges = NaN(draws,quantities,periods,2);
conditional_median = NaN(2,quantities,periods);
for treatment = 1:2
    result = results{treatment};
    rates(treatment,:) = [result.status_counts.completed, ...
        result.status_counts.explosive,result.status_counts.invalid]/draws;
    projections(:,treatment) = result.training_projection_events;
    observations(:,treatment) = observations_reached(result, ...
        artifact.config.training_periods);
    wedges(:,:,:,treatment) = result.learning_draws- ...
        reshape(result.re_reported_path,[1 quantities periods]);
    conditional_median(treatment,:,:) = median( ...
        wedges(:,:,:,treatment),1,'omitnan');
end
joint = results{1}.statuses=="completed" & results{2}.statuses=="completed";
direct_minus_archive = wedges(:,:,:,1)-wedges(:,:,:,2);
direct_minus_archive(~joint,:,:) = NaN;
median_difference = squeeze(median(direct_minus_archive,1,'omitnan'));

% These scalar summaries retain units: maximum absolute displacement over the
% IRF horizon and the horizon-sum of absolute displacements for each quantity.
maximum_wedge = reshape(max(abs(wedges),[],3),draws,quantities,2);
cumulative_wedge = reshape(sum(abs(wedges),3),draws,quantities,2);
maximum_difference = reshape(max(abs(direct_minus_archive),[],3), ...
    draws,quantities);
cumulative_difference = reshape(sum(abs(direct_minus_archive),3), ...
    draws,quantities);
metrics = struct('rate_names',{{'completion','explosive','invalid'}}, ...
    'rates',rates,'projection_events',projections, ...
    'projection_event_rate',mean(projections>0,1,'omitnan'), ...
    'median_projection_events',median(projections,1,'omitnan'), ...
    'observations_reached',observations, ...
    'median_observations_reached',median(observations,1,'omitnan'), ...
    'conditional_learning_minus_re_irf',wedges, ...
    'conditional_median_learning_minus_re_irf',conditional_median, ...
    'maximum_absolute_learning_minus_re_wedge',maximum_wedge, ...
    'cumulative_absolute_learning_minus_re_wedge',cumulative_wedge, ...
    'joint_completion',joint,'joint_completion_rate',mean(joint), ...
    'draw_level_direct_minus_archive_irf',direct_minus_archive, ...
    'median_direct_minus_archive_irf',median_difference, ...
    'draw_level_maximum_absolute_direct_minus_archive',maximum_difference, ...
    'draw_level_cumulative_absolute_direct_minus_archive',cumulative_difference);

stem = fullfile(output_dir,'ep_ee_consumption_audit');
files = struct('mat',[stem '.mat'], ...
    'comparison_pdf',[stem '_comparison.pdf'], ...
    'comparison_png',[stem '_comparison.png'], ...
    'difference_pdf',[stem '_difference.pdf'], ...
    'difference_png',[stem '_difference.png'], ...
    'diagnostics_pdf',[stem '_diagnostics.pdf'], ...
    'diagnostics_png',[stem '_diagnostics.png'],'metrics',metrics);
save_irf_panels(artifact,conditional_median,files);
save_difference_panels(artifact,median_difference,files);
save_diagnostics(artifact,rates,projections,observations,files);
end

function observations = observations_reached(result,requested)
observations = repmat(requested,numel(result.statuses),1);
for draw = 1:numel(result.statuses)
    termination = result.terminations{draw};
    if result.statuses(draw)~="completed" && isfield(termination,'stage') && ...
            strcmp(termination.stage,'training') && isfield(termination,'period')
        observations(draw) = max(0,termination.period-2);
    end
end
end

function save_irf_panels(artifact,medians,files)
fig = figure('Visible','off','Color','white','Position',[50 50 1200 760]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for quantity = 1:4
    ax = nexttile(layout); hold(ax,'on'); yline(ax,0,':');
    paper = plot(ax,squeeze(medians(1,quantity,:)),'LineWidth',1.6);
    archive = plot(ax,squeeze(medians(2,quantity,:)),'--','LineWidth',1.6);
    grid(ax,'on'); title(ax,artifact.quantity_names{quantity});
    xlabel(ax,'Periods after impulse'); ylabel(ax,'Learning minus RE');
    style_axes(ax);
    if quantity==1
        key = legend(ax,[paper archive],artifact.variant_labels,'Location','best');
        key.Color = 'white'; key.TextColor = 'black';
    end
end
heading = title(layout,'EE consumption specification: conditional median IRFs');
heading.Color = 'black';
exportgraphics(fig,files.comparison_pdf,'ContentType','vector', ...
    'BackgroundColor','white');
exportgraphics(fig,files.comparison_png,'Resolution',250, ...
    'BackgroundColor','white');
clear cleanup
end

function save_difference_panels(artifact,difference,files)
fig = figure('Visible','off','Color','white','Position',[50 50 1200 760]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for quantity = 1:4
    ax = nexttile(layout); hold(ax,'on'); yline(ax,0,':');
    plot(ax,difference(quantity,:),'LineWidth',1.6); grid(ax,'on');
    title(ax,artifact.quantity_names{quantity}); xlabel(ax,'Periods after impulse');
    ylabel(ax,'Direct minus archive');
    style_axes(ax);
end
heading = title(layout,'Paired median EE specification difference');
heading.Color = 'black';
exportgraphics(fig,files.difference_pdf,'ContentType','vector', ...
    'BackgroundColor','white');
exportgraphics(fig,files.difference_png,'Resolution',250, ...
    'BackgroundColor','white');
clear cleanup
end

function save_diagnostics(artifact,rates,projections,observations,files)
fig = figure('Visible','off','Color','white','Position',[50 50 1200 420]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
labels = {'Paper direct','Archive fixed RE'};
ax = nexttile(layout); bar(ax,rates); ylim(ax,[0 1]); grid(ax,'on');
title(ax,'Path outcomes'); xticklabels(ax,labels);
style_axes(ax); key = legend(ax,{'Completed','Explosive','Invalid'}, ...
    'Location','best'); key.Color = 'white'; key.TextColor = 'black';
plot_distribution(nexttile(layout),projections,labels,'Rejected updates');
plot_distribution(nexttile(layout),observations,labels,'Observations reached');
heading = title(layout,sprintf( ...
    'EE consumption audit diagnostics (%d paired draws)', ...
    artifact.config.draw_count)); heading.Color = 'black';
exportgraphics(fig,files.diagnostics_pdf,'ContentType','vector', ...
    'BackgroundColor','white');
exportgraphics(fig,files.diagnostics_png,'Resolution',250, ...
    'BackgroundColor','white');
clear cleanup
end

function plot_distribution(ax,values,labels,heading)
hold(ax,'on');
for treatment = 1:2
    plot(ax,repmat(treatment,size(values,1),1),values(:,treatment),'o', ...
        'MarkerSize',4,'Color',[0.65 0.65 0.65]);
    plot(ax,treatment,median(values(:,treatment),'omitnan'),'kd', ...
        'MarkerFaceColor','k','MarkerSize',7);
end
grid(ax,'on'); xlim(ax,[0.5 2.5]); xticks(ax,1:2); xticklabels(ax,labels);
title(ax,heading); style_axes(ax);
end

function style_axes(ax)
ax.Color = 'white'; ax.XColor = 'black'; ax.YColor = 'black';
ax.Title.Color = 'black'; ax.XLabel.Color = 'black'; ax.YLabel.Color = 'black';
end
