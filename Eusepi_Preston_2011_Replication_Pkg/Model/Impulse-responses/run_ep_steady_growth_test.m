function artifact = run_ep_steady_growth_test(config,output_dir)
%% RUN_EP_STEADY_GROWTH_TEST Test E&P deterministic growth against gamma_bar=1.
% Both calibrations receive the same one-time structural technology-growth
% innovation. The IID stochastic technology-growth process is otherwise retained.

if nargin==0
    config=learning_comparison_config();
    output_dir=fullfile(fileparts(mfilename('fullpath')),'artifacts', ...
        'comparisons','ep_steady_growth_test');
elseif nargin~=2
    error('EPGrowthTest:RequiredArguments', ...
        'Supply both config and output_dir, or neither.');
end
setup_ir_paths();
if ~isfolder(output_dir), mkdir(output_dir); end

baseline_config=config;
baseline_config.ep_steady_state_growth=exp(0.0053);
baseline=run_learning_comparison_panels(baseline_config, ...
    fullfile(output_dir,'baseline_growth'));

no_growth_config=config;
no_growth_config.ep_steady_state_growth=1;
no_growth=run_learning_comparison_panels(no_growth_config, ...
    fullfile(output_dir,'zero_deterministic_growth'));

ids={'ep_ee','ep_ih'};
differences=cell(1,2);
for j=1:2
    baseline_result=result_by_id(baseline,ids{j});
    no_growth_result=result_by_id(no_growth,ids{j});
    differences{j}=struct('id',ids{j},'label',baseline_result.label, ...
        'quantity_names',{baseline_result.quantity_names}, ...
        'learning_median',no_growth_result.summary.learning_median- ...
        baseline_result.summary.learning_median, ...
        're',no_growth_result.summary.re-baseline_result.summary.re);
end
artifact=struct('description',[ ...
    'Effect of setting E&P deterministic gross technology growth to one; ' ...
    'both calibrations receive the same structural technology-growth shock.'], ...
    'baseline_growth',exp(0.0053),'alternative_growth',1, ...
    'technology_shock_percent', ...
    config.technology_shock_percent, ...
    'baseline',baseline,'no_growth',no_growth,'differences',{differences}, ...
    'figure_files',{{}});
artifact.figure_files=render_differences(artifact,config.plot_periods,output_dir);
save(fullfile(output_dir,'ep_steady_growth_test.mat'),'-struct','artifact','-v7.3');
fprintf('Saved the E&P steady-growth sensitivity test to:\n  %s\n',output_dir);
end

function result=result_by_id(artifact,id)
index=find(strcmp(artifact.specification_ids,id),1);
assert(~isempty(index),'EPGrowthTest:MissingSpecification', ...
    'Comparison artifact is missing %s.',id);
result=artifact.results{index};
end

function files=render_differences(artifact,periods,output_dir)
fig=figure('Visible','off','Color','white','Position',[50 50 1350 620]);
cleanup=onCleanup(@() close(fig));
layout=tiledlayout(fig,2,4,'TileSpacing','compact','Padding','compact');
for row=1:2
    difference=artifact.differences{row};
    for column=1:4
        ax=nexttile(layout);
        plot(ax,periods,difference.learning_median(column,periods), ...
            'k-','LineWidth',1.5);
        hold(ax,'on');
        plot(ax,periods,difference.re(column,periods),'k--','LineWidth',1.5);
        yline(ax,0,'Color',[0.65 0.65 0.65]);
        title(ax,sprintf('%s - %s',difference.label, ...
            difference.quantity_names{column}));
        xlabel(ax,'Quarters'); ylabel(ax,'Percentage-point difference');
        xlim(ax,[periods(1) periods(end)]); grid(ax,'on');
    end
end
legend(nexttile(layout,1),{'Learning median','RE'},'Location','best');
title(layout, ...
    'E&P response with gross trend growth 1 minus response with exp(0.0053)');
pdf=fullfile(output_dir,'ep_steady_growth_difference.pdf');
png=fullfile(output_dir,'ep_steady_growth_difference.png');
exportgraphics(fig,pdf,'ContentType','vector');
exportgraphics(fig,png,'Resolution',250);
files={pdf,png};
clear cleanup
end
