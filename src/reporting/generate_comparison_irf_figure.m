function figure_handle = generate_comparison_irf_figure(comparison)
%% GENERATE_COMPARISON_IRF_FIGURE Plot case medians and RE benchmarks.
% Export and file naming deliberately remain caller responsibilities.

validate_artifact(comparison);
if comparison.kind~="comparison"
    error('AdaptiveLearning:UnsupportedArtifact', ...
        'Comparison figure requires a comparison artifact.');
end
series = comparison.cases{1}.series;
figure_handle = figure('Visible','off','Color','white');
layout = tiledlayout(figure_handle,'flow');
for quantity = 1:numel(series)
    axes_handle = nexttile(layout);
    hold(axes_handle,'on');
    labels = strings(1,2*numel(comparison.cases));
    for j = 1:numel(comparison.cases)
        item = comparison.cases{j};
        summary = artifact_summary(item);
        horizons = item.timing.horizons;
        plot(axes_handle,horizons,summary.learning_median(quantity,:), ...
            'LineWidth',1.5);
        plot(axes_handle,horizons,summary.re(quantity,:),'--', ...
            'LineWidth',1);
        labels(2*j-1) = item.case.label+" learning";
        labels(2*j) = item.case.label+" RE";
    end
    title(axes_handle,string(series(quantity).label),'Interpreter','none');
    xlabel(axes_handle,'Quarters'); ylabel(axes_handle,'Percent deviation');
    grid(axes_handle,'on');
    legend(axes_handle,cellstr(labels),'Interpreter','none');
end
end
