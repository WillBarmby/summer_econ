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
validate_ir_config(experiment);
assert(ischar(mod_path)||(isstring(mod_path)&&isscalar(mod_path)), ...
    'DynareIR:InvalidModelPath','mod_path must be text.');
assert(ischar(output_dir)||(isstring(output_dir)&&isscalar(output_dir)), ...
    'DynareIR:InvalidOutputDirectory','output_dir must be text.');
if ~isfolder(output_dir), mkdir(output_dir); end

model=load_dynare_71_linear_model(mod_path);
[plugin,initial_learning]=make_dynare_ih_learning_plugin( ...
    model,learning_config,experiment.main.shock_scale^2);
main=experiment.main;
horizon=main.impulse_horizon-1;
raw=NaN(main.n_draws,4,horizon);
draws=cell(main.n_draws,1);

% Preserve the benchmark's random-number behavior: one T_tot draw per
% replication, partitioned into training and post-training innovations.
rng(experiment.baseline_seed,'twister');
for draw_index=1:main.n_draws
    innovations=randn(1,main.training_sample_length+main.impulse_horizon);
    training=main.shock_scale*innovations(1:main.training_sample_length);
    ir_shocks=main.shock_scale*innovations( ...
        main.training_sample_length+1:end-1);
    impulse=zeros(numel(model.shock_names),1);
    impulse(1)=main.normalized_shock_size;
    paired=simulate_paired_irf(plugin,training,ir_shocks,impulse, ...
        zeros(numel(model.variable_names),1),initial_learning,main.explosion_policy);
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
artifact.plot_data=summarize_quantities(raw(completed,:,:),artifact.re_quantities);
artifact.figure_files=render_quantities(artifact.plot_data,artifact.quantity_names, ...
    status,output_dir,min(40,horizon));
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

function data=summarize_quantities(raw,re)
values=squeeze(raw);
if ndims(values)==2, values=reshape(values,1,size(values,1),size(values,2)); end
ordered=sort(values,1);
n=size(ordered,1);
data=struct('learning_median',squeeze(median(values,1)), ...
    'learning_low',squeeze(ordered(max(1,ceil(0.25*n)),:,:)), ...
    'learning_high',squeeze(ordered(min(n,ceil(0.75*n)),:,:)),'re',re, ...
    'band_probabilities',[0.25 0.75]);
assert(all(data.learning_low<=data.learning_high,'all'), ...
    'DynareIR:ReversedBands','Learning percentile bands are reversed.');
end

function files=render_quantities(data,names,status,output_dir,plot_horizon)
fig=figure('Visible','off','Color','white','Position',[100 100 1100 760]);
cleanup=onCleanup(@() close(fig));
layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
periods=1:plot_horizon;
for j=1:4
    ax=nexttile(layout);
    fill(ax,[periods fliplr(periods)], ...
        [data.learning_low(j,periods) fliplr(data.learning_high(j,periods))], ...
        [0.85 0.85 0.85],'EdgeColor','none'); hold(ax,'on');
    plot(ax,periods,data.learning_median(j,periods),'k-','LineWidth',1.6);
    plot(ax,periods,data.re(j,periods),'k--','LineWidth',1.6);
    title(ax,names{j}); xlabel(ax,'Quarters'); ylabel(ax,'% deviation');
    xlim(ax,[1 plot_horizon]); grid(ax,'on');
    legend(ax,{'25th–75th percentile','Learning median','RE'},'Location','best');
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
