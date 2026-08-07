function figure_handle = generate_artifact_figure(artifact,specification)
%% GENERATE_ARTIFACT_FIGURE Plot reported artifact series in memory.
% File naming and export are intentionally separate caller responsibilities.

report = report_artifact(artifact,specification);
figure_handle = figure('Visible','off','Color','white');
axes_handle = axes(figure_handle);
plot(axes_handle,report.horizons,report.values','LineWidth',1.5);
grid(axes_handle,'on');
xlabel(axes_handle,report.x_label);
ylabel(axes_handle,report.y_label);
title(axes_handle,report.title,'Interpreter','none');
legend(axes_handle,cellstr(report.series_labels), ...
    'Location','best','Interpreter','none');
end
