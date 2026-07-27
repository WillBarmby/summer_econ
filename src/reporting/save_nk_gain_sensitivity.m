function files = save_nk_gain_sensitivity(sensitivity,output_dir)
%% SAVE_NK_GAIN_SENSITIVITY Save amplification metrics and completion rates.

gains = sensitivity.gains;
periods = sensitivity.config.plot_periods;
technology = collect_metrics(sensitivity.technology_results,periods);
risk = collect_metrics(sensitivity.risk_results,periods);
mat_path = fullfile(output_dir,'nk_gain_sensitivity.mat');
pdf_path = fullfile(output_dir,'nk_gain_sensitivity.pdf');
png_path = fullfile(output_dir,'nk_gain_sensitivity.png');

fig = figure('Visible','off','Color','white','Position',[50 50 1500 480]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
ax = nexttile(layout);
plot(ax,gains,technology.wedges,'o-','LineWidth',1.4);
title(ax,'Technology shock'); ylabel(ax,'Maximum |median EE - RE|');
legend(ax,sensitivity.technology_quantity_names,'Location','best');
format_axis(ax,gains);

ax = nexttile(layout);
plot(ax,gains,risk.wedges,'o-','LineWidth',1.4);
title(ax,'Risk-premium shock'); ylabel(ax,'Maximum |median EE - RE|');
legend(ax,sensitivity.risk_quantity_names,'Location','best');
format_axis(ax,gains);

ax = nexttile(layout);
plot(ax,gains,100*technology.completion,'o-','LineWidth',1.5);
hold(ax,'on');
plot(ax,gains,100*risk.completion,'s-','LineWidth',1.5);
ylim(ax,[0 105]); ylabel(ax,'Completed draws (%)');
title(ax,'Simulation completion');
legend(ax,{'technology','risk premium'},'Location','best');
format_axis(ax,gains);
title(layout,'NK one-step EE gain sensitivity');
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path, ...
    'technology_metric',technology,'risk_metric',risk);
save(mat_path,'-struct','sensitivity','-v7.3');
clear cleanup
end

function metrics = collect_metrics(results,periods)
quantity_count = size(results{1}.summary.re,1);
wedges = NaN(numel(results),quantity_count);
completion = NaN(numel(results),1);
for j = 1:numel(results)
    summary = results{j}.summary;
    difference = summary.learning_median(:,periods)-summary.re(:,periods);
    wedges(j,:) = max(abs(difference),[],2,'omitnan').';
    completion(j) = results{j}.status_counts.completed/ ...
        numel(results{j}.statuses);
end
metrics = struct('wedges',wedges,'completion',completion);
end

function format_axis(ax,gains)
xlabel(ax,'Constant gain');
xticks(ax,gains); xlim(ax,[min(gains) max(gains)]);
grid(ax,'on');
end
