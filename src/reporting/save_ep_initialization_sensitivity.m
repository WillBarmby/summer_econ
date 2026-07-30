function files = save_ep_initialization_sensitivity(sensitivity,output_dir)
%% SAVE_EP_INITIALIZATION_SENSITIVITY Summarize and graph prior treatments.
% IRF wedges are computed draw by draw and then summarized by their median.
% This differs from taking the maximum distance between two median paths: the
% draw-level statistic preserves heterogeneous learning outcomes and matches
% the archived initialization experiment's definition.

horizons = sensitivity.training_horizons;
initializations = sensitivity.initializations;
result_grid = sensitivity.results;
n_initial = numel(initializations);
n_horizons = numel(horizons);
n_quantities = numel(sensitivity.quantity_names);
completion = NaN(n_initial,n_horizons);
belief_distance = NaN(n_initial,n_horizons);
median_projections = NaN(n_initial,n_horizons);
median_observations = NaN(n_initial,n_horizons);
irf_wedges = NaN(n_initial,n_horizons,n_quantities);

for initial = 1:n_initial
    for j = 1:n_horizons
        result = result_grid{initial,j};
        re_target = result_grid{1,j}.initial_beliefs.coefficients;
        target = reshape(re_target,[1 size(re_target,1) size(re_target,2)]);
        differences = result.terminal_training_coefficients-target;
        distances = squeeze(sqrt(sum(differences.^2,[2 3])));
        completed = result.statuses=="completed";
        draw_wedges = squeeze(max(abs(result.learning_draws- ...
            reshape(result.re_reported_path, ...
            [1 size(result.re_reported_path)])),[],3));

        completion(initial,j) = mean(completed);
        belief_distance(initial,j) = median(distances,'omitnan');
        median_projections(initial,j) = median( ...
            result.training_projection_events,'omitnan');
        observations = infer_observations(result,horizons(j));
        median_observations(initial,j) = median(observations,'omitnan');
        irf_wedges(initial,j,:) = median(draw_wedges,1,'omitnan');
    end
end

metrics = struct('completion_fraction',completion, ...
    'median_belief_distance_from_re',belief_distance, ...
    'median_projection_events',median_projections, ...
    'median_training_observations_completed',median_observations, ...
    'median_draw_level_irf_wedge_from_re',irf_wedges, ...
    'initializations',initializations,'training_horizons',horizons);

mat_path = fullfile(output_dir,'ep_initialization_sensitivity.mat');
pdf_path = fullfile(output_dir,'ep_initialization_sensitivity.pdf');
png_path = fullfile(output_dir,'ep_initialization_sensitivity.png');
fig = figure('Visible','off','Color','white','Position',[50 50 1500 760]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,4,'TileSpacing','compact','Padding','compact');
for quantity = 1:n_quantities
    ax = nexttile(layout);
    plot_treatments(ax,squeeze(irf_wedges(:,:,quantity)));
    title(ax,sensitivity.quantity_names{quantity});
    ylabel(ax,'Median draw max |EE - RE|'); format_axis(ax,horizons);
end
plot_metric(nexttile(layout),horizons,belief_distance, ...
    'Belief distance from RE','Median Frobenius distance');
plot_metric(nexttile(layout),horizons,completion, ...
    'Completed paths','Fraction'); ylim([-.05 1.05]);
plot_metric(nexttile(layout),horizons,median_projections, ...
    'Capital-slope safeguards','Median rejected updates');
ax = nexttile(layout);
legend_handles = plot_metric(ax,horizons,median_observations, ...
    'Training reached','Median completed observations');
legend(ax,legend_handles,cellstr(strrep(initializations,"_"," ")), ...
    'Location','best');
title(layout,sprintf('E&P EE initialization sensitivity (gain %.4g)', ...
    sensitivity.config.gain));
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path,'metrics',metrics);
clear cleanup
end

function observations = infer_observations(result,requested)
% Completed paths necessarily used every requested training observation.
% For failed paths, the failure period includes the initial state, so period
% t means that t-2 RLS updates were completed before the triggering outcome.
observations = repmat(requested,numel(result.statuses),1);
for draw = 1:numel(result.statuses)
    if result.statuses(draw)~="completed" && ...
            isfield(result.terminations{draw},'period')
        observations(draw) = max(0,result.terminations{draw}.period-2);
    end
end
end

function handles = plot_metric(ax,horizons,values,heading,y_label)
handles = plot_treatments(ax,values);
title(ax,heading); ylabel(ax,y_label); format_axis(ax,horizons);
end

function format_axis(ax,horizons)
xlabel(ax,'Training observations');
xticks(ax,1:numel(horizons));
xticklabels(ax,string(horizons));
grid(ax,'on');
if numel(horizons)>1, xlim(ax,[0.85 numel(horizons)+0.15]); end
end

function handles = plot_treatments(ax,values)
% Use concentric markers and successively thinner lines. When treatments have
% exactly the same value, the larger symbols and wider lines remain visible
% around the later series rather than being completely painted over.
colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.4940 0.1840 0.5560];
markers = {'o','s','d'};
styles = {'-','--',':'};
sizes = [10 7 4];
widths = [3 2 1.25];
positions = 1:size(values,2);
handles = gobjects(size(values,1),1);
hold(ax,'on');
for initial = 1:size(values,1)
    handles(initial) = plot(ax,positions,values(initial,:), ...
        'Color',colors(initial,:),'Marker',markers{initial}, ...
        'LineStyle',styles{initial},'LineWidth',widths(initial), ...
        'MarkerSize',sizes(initial),'MarkerFaceColor','white');
end
end
