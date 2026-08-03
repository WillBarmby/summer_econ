function files = save_nk_gain_sensitivity(sensitivity,output_dir)
%% SAVE_NK_GAIN_SENSITIVITY Save amplification metrics and completion rates.

gains = sensitivity.gains;
technology = sensitivity.summary.technology;
risk = sensitivity.summary.risk_premium;
technology_wedges = reshape( ...
    technology.maximum_absolute_median_learning_minus_re_wedge(1,:,:), ...
    numel(gains),numel(sensitivity.technology_quantity_names));
risk_wedges = reshape( ...
    risk.maximum_absolute_median_learning_minus_re_wedge(1,:,:), ...
    numel(gains),numel(sensitivity.risk_quantity_names));
mat_path = fullfile(output_dir,'nk_gain_sensitivity.mat');
pdf_path = fullfile(output_dir,'nk_gain_sensitivity.pdf');
png_path = fullfile(output_dir,'nk_gain_sensitivity.png');
summary_csv = fullfile(output_dir,'nk_gain_sensitivity_summary.csv');

fig = figure('Visible','off','Color','white','Position',[50 50 1500 480]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
ax = nexttile(layout);
plot(ax,gains,technology_wedges,'o-','LineWidth',1.4);
title(ax,'Technology shock'); ylabel(ax,'Maximum |median EE - RE|');
legend(ax,sensitivity.technology_quantity_names,'Location','best');
format_axis(ax,gains);

ax = nexttile(layout);
plot(ax,gains,risk_wedges,'o-','LineWidth',1.4);
title(ax,'Risk-premium shock'); ylabel(ax,'Maximum |median EE - RE|');
legend(ax,sensitivity.risk_quantity_names,'Location','best');
format_axis(ax,gains);

ax = nexttile(layout);
plot(ax,gains,100*technology.completion_rate,'o-','LineWidth',1.5);
hold(ax,'on');
plot(ax,gains,100*risk.completion_rate,'s-','LineWidth',1.5);
ylim(ax,[0 105]); ylabel(ax,'Completed draws (%)');
title(ax,'Simulation completion');
legend(ax,{'technology','risk premium'},'Location','best');
format_axis(ax,gains);
title(layout,'NK one-step EE gain sensitivity');
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,png_path,'Resolution',250);
files = struct('mat',mat_path,'pdf',pdf_path,'png',png_path, ...
    'summary_csv',summary_csv);
write_summary(technology,risk,summary_csv);
save(mat_path,'-struct','sensitivity','-v7.3');
clear cleanup
end

function write_summary(technology,risk,path)
technology_table = gain_summary_table(technology);
risk_table = gain_summary_table(risk);
technology_table.shock = repmat("technology",height(technology_table),1);
risk_table.shock = repmat("risk_premium",height(risk_table),1);
combined = [technology_table; risk_table];
combined = movevars(combined,'shock','Before',1);
writetable(combined,path);
end

function format_axis(ax,gains)
xlabel(ax,'Constant gain');
xticks(ax,gains); xlim(ax,[min(gains) max(gains)]);
grid(ax,'on');
end
