function files = save_ep_ih_initialization_robustness(artifact,output_dir)
%% SAVE_EP_IH_INITIALIZATION_ROBUSTNESS Build diagnostics and paired figures.

results = artifact.results;
draws = artifact.config.draw_count;
quantities = numel(artifact.quantity_names);
periods = artifact.config.ir_periods;
rates = NaN(2,3);
projection_events = NaN(draws,2);
observations = NaN(draws,2);
belief_distance = NaN(draws,2);
learning_minus_re = cell(1,2);
conditional_median = NaN(2,quantities,periods);

re_coefficients = results{1}.initial_beliefs.coefficients;
for treatment = 1:2
    result = results{treatment};
    rates(treatment,:) = [result.status_counts.completed, ...
        result.status_counts.explosive,result.status_counts.invalid]/draws;
    projection_events(:,treatment) = result.training_projection_events;
    observations(:,treatment) = observations_reached(result, ...
        artifact.config.training_periods);
    difference = result.terminal_training_coefficients- ...
        reshape(re_coefficients,[1 size(re_coefficients)]);
    belief_distance(:,treatment) = squeeze(sqrt(sum(difference.^2,[2 3])));
    belief_distance(~training_completed(result),treatment) = NaN;
    learning_minus_re{treatment} = result.learning_draws- ...
        reshape(result.re_reported_path,[1 quantities periods]);
    conditional_median(treatment,:,:) = median( ...
        learning_minus_re{treatment},1,'omitnan');
end

joint = results{1}.statuses=="completed" & results{2}.statuses=="completed";
coefficient_difference = results{1}.terminal_training_coefficients- ...
    results{2}.terminal_training_coefficients;
paired_belief_distance = squeeze(sqrt(sum(coefficient_difference.^2,[2 3])));
paired_belief_distance(~training_completed(results{1}) | ...
    ~training_completed(results{2})) = NaN;
draw_difference = learning_minus_re{1}-learning_minus_re{2};
draw_difference(~joint,:,:) = NaN;
median_difference = squeeze(median(draw_difference,1,'omitnan'));
metrics = struct('rate_names',{{'completion','explosive','invalid'}}, ...
    'rates',rates,'projection_events',projection_events, ...
    'projection_event_rate',mean(projection_events>0,1,'omitnan'), ...
    'median_projection_events',median(projection_events,1,'omitnan'), ...
    'observations_reached',observations, ...
    'median_observations_reached',median(observations,1,'omitnan'), ...
    'pre_shock_belief_distance_from_re',belief_distance, ...
    'median_pre_shock_belief_distance_from_re', ...
    median(belief_distance,1,'omitnan'), ...
    'paired_pre_shock_belief_distance',paired_belief_distance, ...
    'median_paired_pre_shock_belief_distance', ...
    median(paired_belief_distance,'omitnan'), ...
    'conditional_learning_minus_re_irf',{learning_minus_re}, ...
    'conditional_median_learning_minus_re_irf',conditional_median, ...
    'joint_completion',joint,'joint_completion_rate',mean(joint), ...
    'draw_level_re_minus_half_response',draw_difference, ...
    'median_re_minus_half_response',median_difference);

stem = fullfile(output_dir,'ep_ih_initialization_robustness');
files = struct('mat',[stem '.mat'], ...
    'irf_pdf',[stem '_irfs.pdf'],'irf_png',[stem '_irfs.png'], ...
    'diagnostics_pdf',[stem '_diagnostics.pdf'], ...
    'diagnostics_png',[stem '_diagnostics.png'],'metrics',metrics);
save_irf_figure(artifact,conditional_median,median_difference,files);
save_diagnostic_figure(artifact,rates,projection_events,observations, ...
    belief_distance,files);
end

function observations = observations_reached(result,requested)
observations = repmat(requested,numel(result.statuses),1);
for draw = 1:numel(result.statuses)
    if result.statuses(draw)~="completed" && ...
            isfield(result.terminations{draw},'stage') && ...
            strcmp(result.terminations{draw}.stage,'training') && ...
            isfield(result.terminations{draw},'period')
        observations(draw) = max(0,result.terminations{draw}.period-2);
    end
end
end

function completed = training_completed(result)
completed = true(numel(result.statuses),1);
for draw = 1:numel(result.statuses)
    completed(draw) = result.statuses(draw)=="completed" || ...
        ~isfield(result.terminations{draw},'stage') || ...
        ~strcmp(result.terminations{draw}.stage,'training');
end
end

function save_irf_figure(artifact,medians,difference,files)
fig = figure('Visible','off','Color','white','Position',[50 50 1400 920]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
labels = {'RE initialization','Half-RE initialization','RE minus half-RE'};
for row = 1:3
    for quantity = 1:4
        ax = nexttile(layout); hold(ax,'on'); yline(ax,0,':');
        if row<3, values = squeeze(medians(row,quantity,:));
        else, values = difference(quantity,:).'; end
        plot(ax,1:numel(values),values,'LineWidth',1.5);
        grid(ax,'on'); title(ax,artifact.quantity_names{quantity});
        if quantity==1, ylabel(ax,labels{row}); end
        if row==3, xlabel(ax,'Periods after impulse'); end
    end
end
title(layout,'E&P IH conditional learning-minus-RE responses');
exportgraphics(fig,files.irf_pdf,'ContentType','vector');
exportgraphics(fig,files.irf_png,'Resolution',250);
clear cleanup
end

function save_diagnostic_figure(artifact,rates,projections,observations,distances,files)
fig = figure('Visible','off','Color','white','Position',[50 50 1200 760]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
labels = {'RE','Half-RE'};
ax = nexttile(layout); bar(ax,rates); ylim(ax,[0 1]); grid(ax,'on');
title(ax,'Path outcomes'); ylabel(ax,'Fraction'); xticklabels(ax,labels);
legend(ax,{'Completed','Explosive','Invalid'},'Location','best');
plot_distribution(nexttile(layout),projections,labels,'Rejected updates');
plot_distribution(nexttile(layout),observations,labels,'Training observations reached');
plot_distribution(nexttile(layout),distances,labels,'Pre-shock belief distance from RE');
title(layout,sprintf('E&P IH initialization diagnostics (%d paired draws)', ...
    artifact.config.draw_count));
exportgraphics(fig,files.diagnostics_pdf,'ContentType','vector');
exportgraphics(fig,files.diagnostics_png,'Resolution',250);
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
title(ax,heading);
end
