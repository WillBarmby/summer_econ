function artifact = run_learning_comparison_panels(config,output_dir)
%% RUN_LEARNING_COMPARISON_PANELS Generate common E&P EE/IH and NK EE panels.

if nargin==0
    config=learning_comparison_config();
    output_dir=fullfile(fileparts(mfilename('fullpath')),'artifacts', ...
        'comparisons','technology_growth_shock_1pct');
elseif nargin~=2
    error('LearningPanels:RequiredArguments', ...
        'Supply both config and output_dir, or neither.');
end
setup_ir_paths();
validate_config(config);
if ~isfolder(output_dir), mkdir(output_dir); end

specifications=make_specifications(config);
results=cell(size(specifications));
for j=1:numel(specifications)
    results{j}=run_specification(specifications{j},config);
    model_dir=fullfile(output_dir,specifications{j}.id);
    if ~isfolder(model_dir), mkdir(model_dir); end
    result=results{j};
    save(fullfile(model_dir,'results.mat'),'result','-v7.3');
end
artifact=struct('experiment','technology_growth_shock_1pct', ...
    'config',config,'quantity_names',{{'output','consumption','investment','hours'}}, ...
    'specification_ids',{cellfun(@(x) x.id,specifications,'UniformOutput',false)}, ...
    'specification_labels',{cellfun(@(x) x.label,specifications,'UniformOutput',false)}, ...
    'results',{results},'figure_files',{{}});
artifact.figure_files=render_panels(artifact,output_dir);
save(fullfile(output_dir,'comparison_results.mat'),'-struct','artifact','-v7.3');
fprintf('Saved common learning panels to %s.\n',output_dir);
end

function specifications=make_specifications(config)
root=fileparts(mfilename('fullpath'));

ep_ee_model=load_dynare_71_linear_model(fullfile(root,'harness','models', ...
    'ep_ee_paper.mod'),'ParameterOverrides', ...
    struct('gamma_bar',config.ep_steady_state_growth));
[ep_ee_plugin,ep_ee_state]=make_dynare_ee_learning_plugin(ep_ee_model, ...
    ep_ee_learning_config("paper",config.gain), ...
    config.training_shock_standard_deviations.ep^2);
ep_ee=make_specification('ep_ee','E&P EE',ep_ee_plugin,ep_ee_state, ...
    config.training_shock_standard_deviations.ep,1, ...
    @report_ep_quantities,{});

ep_ih_model=load_dynare_71_linear_model(fullfile(root,'harness','models', ...
    'ep13_ih_re_linear.mod'),'ParameterOverrides', ...
    struct('gamma_bar',config.ep_steady_state_growth));
ep_ih_learning=ep_ih_learning_config();
ep_ih_learning.gain.value=config.gain;
[ep_ih_plugin,ep_ih_state]=make_dynare_ih_learning_plugin(ep_ih_model, ...
    ep_ih_learning,config.training_shock_standard_deviations.ep^2);
ep_ih=make_specification('ep_ih','E&P IH',ep_ih_plugin,ep_ih_state, ...
    config.training_shock_standard_deviations.ep,1, ...
    @report_ep_quantities,{});

nk_path=fullfile(root,'harness','models','nk_nonlinear_rotemberg_pricing.mod');
nk_calibration=nk_model_calibration_config("iid_comparison");
nk_calibration.parameter_overrides.rho_technology= ...
    config.nk_technology_persistence;
nk_model=load_dynare_71_first_order_model(nk_path, ...
    'ParameterOverrides',nk_calibration.parameter_overrides);
nk_model=convert_first_order_to_log_deviations(nk_model,nk_model.variable_names);
nk_learning=nk_ee_learning_config(config.gain);
if config.nk_technology_persistence>0
    nk_learning.variant="persistent_sensitivity_known_technology_law";
end
[nk_plugin,nk_state]=make_dynare_ee_learning_plugin(nk_model,nk_learning, ...
    config.training_shock_standard_deviations.nk^2);
nk=make_specification('nk_ee','NK EE',nk_plugin,nk_state, ...
    config.training_shock_standard_deviations.nk,0.01, ...
    @report_nk_quantities,{'inflation','interest','marginal_cost'});
specifications={ep_ee,ep_ih,nk};
end

function value=make_specification(id,label,plugin,state,shock_scale, ...
    shock_units_per_percent,reporter,extensions)
value=struct('id',id,'label',label,'plugin',plugin,'initial_learning',state, ...
    'training_shock_standard_deviation',shock_scale, ...
    'shock_units_per_percent',shock_units_per_percent, ...
    'report_quantities',reporter,'extension_names',{extensions});
end

function result=run_specification(specification,config)
plugin=specification.plugin;
n=numel(plugin.model.variable_names);
re_native=make_re_irf(plugin,config.ir_periods);
re_quantities=specification.report_quantities(re_native,plugin.model.variable_names);
impact_innovation=config.technology_shock_percent* ...
    specification.shock_units_per_percent;
re_quantities=re_quantities*impact_innovation;
impulse=zeros(size(plugin.shock_impact,2),1);
impulse(1)=impact_innovation;
policy=struct('magnitude_limit',config.explosion_magnitude_percent, ...
    'reject_nonfinite',true,'variable_indices',1:n);

rng(config.random_seed,'twister');
quantities=NaN(config.draw_count,4,config.ir_periods);
extensions=NaN(config.draw_count,numel(specification.extension_names),config.ir_periods);
statuses=strings(1,config.draw_count);
terminations=cell(1,config.draw_count);
for draw=1:config.draw_count
    innovations=randn(1,config.training_periods+config.ir_periods);
    training=specification.training_shock_standard_deviation* ...
        innovations(1:config.training_periods);
    ir_shocks=specification.training_shock_standard_deviation* ...
        innovations(config.training_periods+1:end);
    paired=simulate_paired_irf(plugin,training,ir_shocks,impulse,zeros(n,1), ...
        specification.initial_learning,policy);
    statuses(draw)=paired.status;
    if paired.status=="completed"
        quantities(draw,:,:)=specification.report_quantities( ...
            paired.native_irf,plugin.model.variable_names);
        extensions(draw,:,:)=report_extensions(paired.native_irf, ...
            plugin.model.variable_names,specification.extension_names);
        terminations{draw}=struct();
    else
        terminations{draw}=paired_termination(paired);
    end
end
completed=statuses=="completed";
assert(any(completed),'LearningPanels:NoCompletedDraws', ...
    'No draws completed for %s.',specification.label);
summary=summarize_paths(quantities(completed,:,:),re_quantities, ...
    config.band_probabilities);
if isempty(specification.extension_names)
    extension_summary=struct();
else
    re_extensions=report_extensions(re_native*impact_innovation, ...
        plugin.model.variable_names,specification.extension_names);
    extension_summary=summarize_paths(extensions(completed,:,:),re_extensions, ...
        config.band_probabilities);
end
result=struct('id',specification.id,'label',specification.label, ...
    'model_name',plugin.model.name,'backend',plugin.model.backend, ...
    'effective_calibration',plugin.model.calibration, ...
    'variable_names',{plugin.model.variable_names}, ...
    'learning_specification',plugin.specification, ...
    'training_shock_standard_deviation', ...
    specification.training_shock_standard_deviation, ...
    'impact_innovation',impact_innovation,'impact_shock', ...
    struct('variable',plugin.model.shock_names{1}, ...
    'technology_percent',config.technology_shock_percent), ...
    'quantity_names',{{'output','consumption','investment','hours'}}, ...
    'raw_quantities',quantities,'summary',summary, ...
    'extension_names',{specification.extension_names}, ...
    'raw_extensions',extensions,'extension_summary',extension_summary, ...
    'statuses',statuses,'terminations',{terminations}, ...
    'status_counts',struct('completed',sum(completed), ...
    'explosive',sum(contains(statuses,"explosive")), ...
    'invalid',sum(contains(statuses,"invalid"))));
end

function path=make_re_irf(plugin,horizon)
alm=plugin.plm_to_alm(plugin.re_plm);
path=zeros(numel(plugin.model.variable_names),horizon);
path(:,1)=alm.shock_impact(:,1);
for period=2:horizon
    path(:,period)=alm.transition*path(:,period-1);
end
end

function values=report_ep_quantities(native,names)
indices=name_indices(names,{'output','consumption','investment','hours','gamma_x'});
technology_level=cumsum(native(indices(5),:),2);
values=[native(indices(1),:)+technology_level; ...
    native(indices(2),:)+technology_level; ...
    native(indices(3),:)+technology_level;native(indices(4),:)];
end

function values=report_nk_quantities(native,names)
indices=name_indices(names,{'output','consumption','investment','hours'});
values=100*native(indices,:);
end

function values=report_extensions(native,names,requested)
if isempty(requested)
    values=zeros(0,size(native,2));
    return
end
indices=name_indices(names,requested);
values=100*native(indices,:);
annualized=ismember(requested,{'inflation','interest'});
values(annualized,:)=4*values(annualized,:);
end

function summary=summarize_paths(raw,re,probabilities)
ordered=sort(raw,1);
n=size(ordered,1);
summary=struct('learning_median',squeeze(median(raw,1)), ...
    'learning_low',squeeze(ordered(max(1,ceil(probabilities(1)*n)),:,:)), ...
    'learning_high',squeeze(ordered(min(n,ceil(probabilities(2)*n)),:,:)), ...
    're',re,'band_probabilities',probabilities);
end

function files=render_panels(artifact,output_dir)
periods=artifact.config.plot_periods;
fig=figure('Visible','off','Color','white','Position',[50 50 1400 900]);
cleanup=onCleanup(@() close(fig));
layout=tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');
axes_by_panel=gobjects(3,4);
for row=1:3
    result=artifact.results{row};
    for column=1:4
        ax=nexttile(layout);
        axes_by_panel(row,column)=ax;
        render_response(ax,result.summary,column,periods);
        title(ax,sprintf('%s — %s',result.label,artifact.quantity_names{column}));
        ylabel(ax,'Percent deviation');
    end
end
for column=1:4
    apply_common_limits(axes_by_panel(:,column));
end
legend(nexttile(layout,1),{'25th–75th percentile','Learning median','RE'}, ...
    'Location','best');
title(layout,sprintf('One-time %.3g%% technology innovation', ...
    artifact.config.technology_shock_percent));
common_pdf=fullfile(output_dir,'common_quantities.pdf');
common_png=fullfile(output_dir,'common_quantities.png');
exportgraphics(fig,common_pdf,'ContentType','vector');
exportgraphics(fig,common_png,'Resolution',250);
clear cleanup

nk=artifact.results{strcmp(artifact.specification_ids,'nk_ee')};
fig=figure('Visible','off','Color','white','Position',[100 100 1100 360]);
cleanup=onCleanup(@() close(fig));
layout=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
for column=1:3
    ax=nexttile(layout);
    render_response(ax,nk.extension_summary,column,periods);
    title(ax,strrep(nk.extension_names{column},'_',' '));
    if ismember(nk.extension_names{column},{'inflation','interest'})
        ylabel(ax,'Annualized percentage points');
    else
        ylabel(ax,'Percent deviation');
    end
end
legend(nexttile(layout,1),{'25th–75th percentile','EE median','RE'}, ...
    'Location','best');
title(layout,'NK nominal and pricing responses');
nominal_pdf=fullfile(output_dir,'nk_nominal_extension.pdf');
nominal_png=fullfile(output_dir,'nk_nominal_extension.png');
exportgraphics(fig,nominal_pdf,'ContentType','vector');
exportgraphics(fig,nominal_png,'Resolution',250);
files={common_pdf,common_png,nominal_pdf,nominal_png};
clear cleanup
end

function apply_common_limits(axes_handles)
limits=cell2mat(get(axes_handles,'YLim'));
lower=min(limits(:,1));
upper=max(limits(:,2));
if lower==upper
    padding=max(1,abs(lower))*0.05;
else
    padding=0.03*(upper-lower);
end
set(axes_handles,'YLim',[lower-padding upper+padding]);
end

function render_response(ax,summary,row,periods)
fill(ax,[periods fliplr(periods)], ...
    [summary.learning_low(row,periods) fliplr(summary.learning_high(row,periods))], ...
    [0.85 0.85 0.85],'EdgeColor','none');
hold(ax,'on');
plot(ax,periods,summary.learning_median(row,periods),'k-','LineWidth',1.5);
plot(ax,periods,summary.re(row,periods),'k--','LineWidth',1.5);
yline(ax,0,'Color',[0.65 0.65 0.65]);
xlabel(ax,'Quarters'); xlim(ax,[periods(1) periods(end)]); grid(ax,'on');
end

function value=paired_termination(paired)
for field={'training','baseline','shocked'}
    path=paired.(field{1});
    if ~isempty(path)&&path.status~="completed"
        value=path.termination;
        return
    end
end
value=struct();
end

function indices=name_indices(names,requested)
[found,indices]=ismember(requested,names);
assert(all(found),'LearningPanels:MissingVariable','Missing variables: %s.', ...
    strjoin(requested(~found),', '));
end

function validate_config(config)
required={'gain','random_seed','draw_count','training_periods','ir_periods', ...
    'plot_periods','band_probabilities','technology_shock_percent', ...
    'ep_steady_state_growth', ...
    'nk_technology_persistence','explosion_magnitude_percent', ...
    'training_shock_standard_deviations'};
assert(isstruct(config)&&isscalar(config)&&isempty(setxor(fieldnames(config),required.')), ...
    'LearningPanels:InvalidConfig','Use the complete comparison configuration.');
assert(config.gain>0&&config.gain<=1&&config.draw_count>=1&& ...
    config.draw_count==fix(config.draw_count)&&config.training_periods>=1&& ...
    config.training_periods==fix(config.training_periods)&&config.ir_periods>=1&& ...
    config.ir_periods==fix(config.ir_periods),'LearningPanels:InvalidConfig', ...
    'Gain, draws, training periods, or IR periods are invalid.');
assert(all(config.plot_periods>=1)&&all(config.plot_periods<=config.ir_periods), ...
    'LearningPanels:InvalidConfig','plot_periods must index the IR horizon.');
assert(isnumeric(config.technology_shock_percent)&& ...
    isscalar(config.technology_shock_percent)&& ...
    isfinite(config.technology_shock_percent)&& ...
    config.technology_shock_percent>0, ...
    'LearningPanels:InvalidConfig', ...
    'technology_shock_percent must be positive and finite.');
assert(isnumeric(config.ep_steady_state_growth)&& ...
    isscalar(config.ep_steady_state_growth)&&isfinite(config.ep_steady_state_growth)&& ...
    config.ep_steady_state_growth>0,'LearningPanels:InvalidConfig', ...
    'ep_steady_state_growth must be positive and finite.');
assert(isnumeric(config.nk_technology_persistence)&& ...
    isscalar(config.nk_technology_persistence)&& ...
    isfinite(config.nk_technology_persistence)&& ...
    config.nk_technology_persistence>=0&&config.nk_technology_persistence<1, ...
    'LearningPanels:InvalidConfig', ...
    'nk_technology_persistence must be in [0,1).');
assert(isequal(size(config.band_probabilities),[1 2])&& ...
    config.band_probabilities(1)>0&&config.band_probabilities(2)<1&& ...
    config.band_probabilities(1)<config.band_probabilities(2), ...
    'LearningPanels:InvalidConfig','Invalid percentile band.');
scales=config.training_shock_standard_deviations;
assert(isequal(sort(fieldnames(scales)),sort({'ep';'nk'}))&& ...
    all(structfun(@(x) isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>0,scales)), ...
    'LearningPanels:InvalidConfig','E&P and NK training shock scales are required.');
end
