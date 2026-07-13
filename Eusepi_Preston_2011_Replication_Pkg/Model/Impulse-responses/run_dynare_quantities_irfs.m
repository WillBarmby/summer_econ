function artifact = run_dynare_quantities_irfs(mod_path,learning_config,experiment,output_dir)
%% RUN_DYNARE_QUANTITIES_IRFS Dynare-driven E&P quantities experiment.
%
% The .mod file supplies the structural equations and RE solution. The
% learning config supplies the restricted PLM and IH expectation rule. The
% experiment config supplies draws, timing, shocks, and explosion policy.

if nargin~=4
    error('DynareIR:RequiredArguments', ...
        'mod_path, learning_config, experiment, and output_dir are required.');
end
setup_ir_paths();
validate_experiment(experiment);
assert(ischar(mod_path)||(isstring(mod_path)&&isscalar(mod_path)), ...
    'DynareIR:InvalidModelPath','mod_path must be text.');
assert(ischar(output_dir)||(isstring(output_dir)&&isscalar(output_dir)), ...
    'DynareIR:InvalidOutputDirectory','output_dir must be text.');
if ~isfolder(output_dir), mkdir(output_dir); end

model=load_dynare_71_linear_model(mod_path);
assert(all(experiment.explosion_policy.variable_indices<=numel(model.variable_names)), ...
    'DynareIR:InvalidExplosionPolicy', ...
    'explosion_policy.variable_indices exceed the Dynare model dimension.');
[plugin,initial_learning]=make_dynare_ih_learning_plugin( ...
    model,learning_config,experiment.shock.simulation_scale^2);
shock_index=name_index(model.shock_names,experiment.shock.name,'impulse shock');
horizon=experiment.ir_periods;
raw=NaN(experiment.draw_count,4,horizon);
draws=cell(experiment.draw_count,1);

% Preserve the benchmark's random-number behavior: one T_tot draw per
% replication, partitioned into training and post-training innovations.
rng(experiment.random_seed,'twister');
for draw_index=1:experiment.draw_count
    % The extra final innovation preserves the original T_tot draw length;
    % as in the original simulator, it is not consumed by a transition.
    innovations=randn(1,experiment.training_periods+experiment.ir_periods+1);
    training=experiment.shock.simulation_scale* ...
        innovations(1:experiment.training_periods);
    ir_shocks=experiment.shock.simulation_scale*innovations( ...
        experiment.training_periods+1:end-1);
    impulse=zeros(numel(model.shock_names),1);
    impulse(shock_index)=experiment.shock.impulse_size;
    paired=simulate_paired_irf(plugin,training,ir_shocks,impulse, ...
        zeros(numel(model.variable_names),1),initial_learning,experiment.explosion_policy);
    draws{draw_index}=compact_draw_report(paired);
    if paired.status=="completed"
        raw(draw_index,:,:)=quantities_from_native_irf( ...
            paired.native_irf,model.variable_names);
    end
end

status=summarize_draw_statuses(draws);
completed=status.statuses=="completed";
artifact=struct('mod_path',char(mod_path),'model_name',model.name, ...
    'learning_config',learning_config,'experiment',experiment, ...
    'quantity_names',{{'consumption','output','investment','hours'}}, ...
    'raw_quantities',raw,'draws',{draws},'status',status, ...
    're_quantities',re_quantities(plugin,horizon),'plot_data',[],'figure_files',{{}});
save(fullfile(output_dir,'dynare_quantities_results.mat'),'-struct','artifact','-v7.3');
if ~any(completed)
    error('DynareIR:NoCompletedDraws', ...
        'No completed draws; diagnostics were saved before plotting failed.');
end
artifact.plot_data=summarize_quantities(raw(completed,:,:),artifact.re_quantities, ...
    experiment.band_probabilities);
artifact.figure_files=render_quantities(artifact.plot_data,artifact.quantity_names, ...
    status,output_dir,experiment.plot_periods,experiment.band_probabilities);
save(fullfile(output_dir,'dynare_quantities_results.mat'),'-struct','artifact','-v7.3');
end

function report=compact_draw_report(paired)
report=struct('status',paired.status, ...
    'training',compact_path_report(paired.training), ...
    'baseline',compact_path_report(paired.baseline), ...
    'shocked',compact_path_report(paired.shocked));
end

function report=compact_path_report(path)
if isempty(path)
    report=struct('status',"not_run",'termination',struct());
else
    report=struct('status',path.status,'termination',path.termination);
end
end

function quantities=quantities_from_native_irf(native,names)
indices=name_indices(names,{'consumption','output','investment','hours','gamma_x'});
growth_adjustment=cumsum(native(indices(5),:),2);
quantities=[native(indices(1),:)+growth_adjustment; ...
    native(indices(2),:)+growth_adjustment; ...
    native(indices(3),:)+growth_adjustment;native(indices(4),:)];
end

function quantities=re_quantities(plugin,horizon)
plm=plugin.re_plm;
alm=plugin.plm_to_alm(plm);
native=zeros(size(alm.transition,1),horizon);
native(:,1)=alm.shock_impact(:,1);
for period=2:horizon
    native(:,period)=alm.transition*native(:,period-1);
end
quantities=quantities_from_native_irf(native,plugin.model.variable_names);
end

function data=summarize_quantities(raw,re,probabilities)
values=squeeze(raw);
if ndims(values)==2, values=reshape(values,1,size(values,1),size(values,2)); end
ordered=sort(values,1);
n=size(ordered,1);
data=struct('learning_median',squeeze(median(values,1)), ...
    'learning_low',squeeze(ordered(max(1,ceil(probabilities(1)*n)),:,:)), ...
    'learning_high',squeeze(ordered(min(n,ceil(probabilities(2)*n)),:,:)),'re',re, ...
    'band_probabilities',probabilities);
assert(all(data.learning_low<=data.learning_high,'all'), ...
    'DynareIR:ReversedBands','Learning percentile bands are reversed.');
end

function files=render_quantities(data,names,status,output_dir,periods,probabilities)
fig=figure('Visible','off','Color','white','Position',[100 100 1100 760]);
cleanup=onCleanup(@() close(fig));
layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for j=1:4
    ax=nexttile(layout);
    fill(ax,[periods fliplr(periods)], ...
        [data.learning_low(j,periods) fliplr(data.learning_high(j,periods))], ...
        [0.85 0.85 0.85],'EdgeColor','none'); hold(ax,'on');
    plot(ax,periods,data.learning_median(j,periods),'k-','LineWidth',1.6);
    plot(ax,periods,data.re(j,periods),'k--','LineWidth',1.6);
    title(ax,names{j}); xlabel(ax,'Quarters'); ylabel(ax,'% deviation');
    xlim(ax,[periods(1) periods(end)]); grid(ax,'on');
    band_label=sprintf('%gth–%gth percentile',100*probabilities(1),100*probabilities(2));
    legend(ax,{band_label,'Learning median','RE'},'Location','best');
end
title(layout,sprintf(['Eusepi–Preston quantities | completed %d, ' ...
    'explosive %d, invalid %d'],status.completed,status.explosive,status.invalid));
pdf=fullfile(output_dir,'dynare_quantities.pdf');
png=fullfile(output_dir,'dynare_quantities.png');
exportgraphics(fig,pdf,'ContentType','vector');
exportgraphics(fig,png,'Resolution',250);
files={pdf,png};
clear cleanup
end

function status=summarize_draw_statuses(draws)
statuses=cellfun(@(value) string(value.status),draws);
status=struct('total',numel(draws),'completed',sum(statuses=="completed"), ...
    'explosive',sum(contains(statuses,"explosive")), ...
    'invalid',sum(contains(statuses,"invalid")), ...
    'other',sum(~(statuses=="completed"|contains(statuses,"explosive")| ...
    contains(statuses,"invalid"))),'statuses',statuses);
end

function indices=name_indices(names,requested)
[found,indices]=ismember(requested,names);
assert(all(found),'DynareIR:MissingQuantity','The .mod file is missing: %s.', ...
    strjoin(requested(~found),', '));
end

function index=name_index(names,requested,label)
index=find(strcmp(names,requested),1);
assert(~isempty(index),'DynareIR:MissingName','Missing %s: %s.',label,requested);
end

function validate_experiment(value)
required={'random_seed','draw_count','training_periods','ir_periods', ...
    'plot_periods','band_probabilities','shock','explosion_policy'};
assert(isstruct(value)&&isscalar(value)&&isempty(setxor(fieldnames(value),required.')), ...
    'DynareIR:InvalidExperiment','A complete Dynare IR experiment is required.');
positive_integer(value.random_seed,'random_seed');
positive_integer(value.draw_count,'draw_count');
positive_integer(value.training_periods,'training_periods');
positive_integer(value.ir_periods,'ir_periods');
assert(isnumeric(value.plot_periods)&&isrow(value.plot_periods)&& ...
    ~isempty(value.plot_periods)&&all(value.plot_periods==floor(value.plot_periods))&& ...
    all(value.plot_periods>=1)&all(value.plot_periods<=value.ir_periods), ...
    'DynareIR:InvalidPlotPeriods','plot_periods must index the simulated IR.');
assert(isequal(size(value.band_probabilities),[1 2])&& ...
    all(value.band_probabilities>0)&all(value.band_probabilities<1)&& ...
    value.band_probabilities(1)<value.band_probabilities(2), ...
    'DynareIR:InvalidBands','band_probabilities must be increasing values in (0,1).');
shock_required={'name','simulation_scale','impulse_size'};
assert(isstruct(value.shock)&&isscalar(value.shock)&& ...
    isempty(setxor(fieldnames(value.shock),shock_required.')), ...
    'DynareIR:InvalidShock','A complete named shock specification is required.');
assert((ischar(value.shock.name)||(isstring(value.shock.name)&&isscalar(value.shock.name)))&& ...
    strlength(string(value.shock.name))>0,'DynareIR:InvalidShock','shock.name is required.');
assert(isnumeric(value.shock.simulation_scale)&&isscalar(value.shock.simulation_scale)&& ...
    isfinite(value.shock.simulation_scale)&&value.shock.simulation_scale>0, ...
    'DynareIR:InvalidShock','shock.simulation_scale must be positive and finite.');
assert(isnumeric(value.shock.impulse_size)&&isscalar(value.shock.impulse_size)&& ...
    isfinite(value.shock.impulse_size),'DynareIR:InvalidShock', ...
    'shock.impulse_size must be finite.');
validate_explosion_policy(value.explosion_policy);
end

function positive_integer(value,label)
assert(isnumeric(value)&&isscalar(value)&&isfinite(value)&&value>=1&&value==floor(value), ...
    'DynareIR:InvalidInteger','%s must be a positive integer.',label);
end

function validate_explosion_policy(policy)
required={'magnitude_limit','reject_nonfinite','variable_indices'};
assert(isstruct(policy)&&isscalar(policy)&&isempty(setxor(fieldnames(policy),required.')), ...
    'DynareIR:InvalidExplosionPolicy','A complete explosion policy is required.');
assert(isnumeric(policy.magnitude_limit)&&isscalar(policy.magnitude_limit)&& ...
    isfinite(policy.magnitude_limit)&&policy.magnitude_limit>0, ...
    'DynareIR:InvalidExplosionPolicy','magnitude_limit must be positive and finite.');
assert(islogical(policy.reject_nonfinite)&&isscalar(policy.reject_nonfinite), ...
    'DynareIR:InvalidExplosionPolicy','reject_nonfinite must be logical.');
assert(isnumeric(policy.variable_indices)&&isvector(policy.variable_indices)&& ...
    ~isempty(policy.variable_indices)&&all(policy.variable_indices>=1)&& ...
    all(policy.variable_indices==floor(policy.variable_indices)), ...
    'DynareIR:InvalidExplosionPolicy','variable_indices must be positive integers.');
end
