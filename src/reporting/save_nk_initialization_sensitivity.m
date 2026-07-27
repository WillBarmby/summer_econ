function files = save_nk_initialization_sensitivity(sensitivity,output_dir)
%% SAVE_NK_INITIALIZATION_SENSITIVITY Save IRF and belief-convergence metrics.

horizons = sensitivity.training_horizons;
initializations = sensitivity.initializations;
result_grid = sensitivity.results;
irf_wedges = NaN(2,numel(horizons),4);
belief_distance = NaN(2,numel(horizons));
completion = NaN(2,numel(horizons));
median_projections = NaN(2,numel(horizons));
for initial = 1:2
    for j = 1:numel(horizons)
        result = result_grid{initial,j};
        difference = result.summary.learning_median-result.summary.re;
        irf_wedges(initial,j,:) = max(abs(difference),[],2);
        terminal = result.terminal_training_coefficients;
        re_coefficients = result.initial_beliefs.coefficients;
        if initial==2
            % The zero-treatment artifact stores zero initial coefficients; the
            % RE target is recovered from the matched informed treatment.
            re_coefficients = result_grid{1,j}.initial_beliefs.coefficients;
        end
        re_target = reshape(re_coefficients, ...
            [1 size(re_coefficients,1) size(re_coefficients,2)]);
        % The estimated capital transition is retained for E&P comparability,
        % but no capital lead enters the corrected NK structural equations.
        % Exclude that diagnostic row from the decision-relevant distance.
        learned = result.learning_specification.learned_outcomes;
        decision_rows = ~strcmp(learned,'capital');
        distances = squeeze(sqrt(sum( ...
            (terminal(:,decision_rows,:)-re_target(:,decision_rows,:)).^2, ...
            [2 3])));
        belief_distance(initial,j) = median(distances,'omitnan');
        completion(initial,j) = result.status_counts.completed/ ...
            numel(result.statuses);
        median_projections(initial,j) = ...
            median(result.training_projection_events,'omitnan');
    end
end

mat_path = fullfile(output_dir,'nk_initialization_sensitivity.mat');
pdf_path = fullfile(output_dir,'nk_initialization_sensitivity.pdf');
png_path = fullfile(output_dir,'nk_initialization_sensitivity.png');
fig = figure('Visible','off','Color','white','Position',[50 50 1450 720]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for quantity = 1:4
    ax = nexttile(layout);
    plot(ax,horizons,squeeze(irf_wedges(1,:,quantity)),'o-','LineWidth',1.5);
    hold(ax,'on');
    plot(ax,horizons,squeeze(irf_wedges(2,:,quantity)),'s-','LineWidth',1.5);
    title(ax,sensitivity.quantity_names{quantity});
    ylabel(ax,'Maximum |median EE - RE|'); format_axis(ax,horizons);
end
ax = nexttile(layout);
plot(ax,horizons,belief_distance(1,:),'o-','LineWidth',1.5); hold(ax,'on');
plot(ax,horizons,belief_distance(2,:),'s-','LineWidth',1.5);
title(ax,'Belief distance from RE'); ylabel(ax,'Median Frobenius distance');
format_axis(ax,horizons);
ax = nexttile(layout);
plot(ax,horizons,median_projections(1,:),'o-','LineWidth',1.5); hold(ax,'on');
plot(ax,horizons,median_projections(2,:),'s-','LineWidth',1.5);
title(ax,'Capital-slope safeguards'); ylabel(ax,'Median projection events');
format_axis(ax,horizons);
legend(ax,{'RE initialization','Zero coefficients'},'Location','best');
title(layout,'NK EE initialization and training sensitivity');
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
metrics = struct('irf_wedges',irf_wedges, ...
    'belief_distance_from_re',belief_distance,'completion',completion, ...
    'median_projection_events',median_projections, ...
    'initializations',initializations,'training_horizons',horizons);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path,'metrics',metrics);
save(mat_path,'-struct','sensitivity','-v7.3');
clear cleanup
end

function format_axis(ax,horizons)
xlabel(ax,'Training observations'); xticks(ax,horizons);
xlim(ax,[min(horizons) max(horizons)]); grid(ax,'on');
end
