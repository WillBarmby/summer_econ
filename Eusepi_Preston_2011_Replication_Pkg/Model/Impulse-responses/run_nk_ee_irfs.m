function artifact = run_nk_ee_irfs(config,output_dir)
%% RUN_NK_EE_IRFS Compare NK Euler-equation learning with rational expectations.

if nargin==0
    config=nk_ee_ir_config();
    output_dir=fullfile(fileparts(mfilename('fullpath')),'artifacts','nk_ee_custom');
elseif nargin~=2
    error('NKEEIR:RequiredArguments','Supply both config and output_dir, or neither.');
end
setup_ir_paths();
validate_config(config);
if ~isfolder(output_dir), mkdir(output_dir); end

root=fileparts(mfilename('fullpath'));
model_path=fullfile(root,'harness','models','nk_nonlinear_rotemberg_pricing.mod');
calibration=nk_model_calibration_config("iid_comparison");
model=load_dynare_71_first_order_model(model_path, ...
    'ParameterOverrides',calibration.parameter_overrides);
model=convert_first_order_to_log_deviations(model,model.variable_names);
learning=nk_ee_learning_config(config.gain);
[plugin,initial_learning]=make_dynare_ee_learning_plugin(model,learning, ...
    config.training_shock_standard_deviation^2);

output_index=name_index(model.variable_names,'output');
shock_index=name_index(model.shock_names,'eps_technology');
re=make_re_irf(plugin,config.ir_periods);
impact_innovation=(config.impact_output_percent/100)/re(output_index,1);
impulse=zeros(numel(model.shock_names),1);
impulse(shock_index)=impact_innovation;
re=re*impact_innovation;

policy=struct('magnitude_limit',config.explosion_magnitude_percent/100, ...
    'reject_nonfinite',true,'variable_indices',1:numel(model.variable_names));
rng(config.random_seed,'twister');
raw=NaN(config.draw_count,numel(model.variable_names),config.ir_periods);
statuses=strings(1,config.draw_count);
terminations=cell(1,config.draw_count);
for draw=1:config.draw_count
    innovations=randn(1,config.training_periods+config.ir_periods);
    training=config.training_shock_standard_deviation* ...
        innovations(1:config.training_periods);
    ir_shocks=config.training_shock_standard_deviation* ...
        innovations(config.training_periods+1:end);
    paired=simulate_paired_irf(plugin,training,ir_shocks,impulse, ...
        zeros(numel(model.variable_names),1),initial_learning,policy);
    statuses(draw)=paired.status;
    if paired.status=="completed"
        raw(draw,:,:)=paired.native_irf;
        terminations{draw}=struct();
    else
        terminations{draw}=paired_termination(paired);
    end
end

completed=statuses=="completed";
if any(completed)
    summary=summarize_paths(raw(completed,:,:),re,config.band_probabilities);
else
    summary=struct();
end
reporting=reporting_contract(model.variable_names);
if any(completed)
    reported_summary=apply_reporting(summary,reporting,model.variable_names);
else
    reported_summary=struct();
end
artifact=struct('model_name',model.name,'model_path',model_path, ...
    'backend',model.backend,'dynare_version',model.dynare.version, ...
    'calibration_variant',calibration.variant, ...
    'effective_calibration',model.calibration,'normalization',model.normalization, ...
    'learning_specification',learning,'config',config, ...
    'shock_name','eps_technology','impact_innovation',impact_innovation, ...
    'variable_names',{model.variable_names},'raw_learning_irfs',raw, ...
    'raw_re_irf',re,'summary',summary,'reporting',reporting, ...
    'reported_summary',reported_summary, ...
    'statuses',statuses,'terminations',{terminations}, ...
    'status_counts',struct('completed',sum(completed), ...
    'explosive',sum(contains(statuses,"explosive")), ...
    'invalid',sum(contains(statuses,"invalid"))),'figure_files',{{}});
save(fullfile(output_dir,'nk_ee_irfs.mat'),'-struct','artifact','-v7.3');
if ~any(completed)
    error('NKEEIR:NoCompletedDraws','No NK EE draws completed; diagnostics were saved.');
end
artifact.figure_files=render_irfs(artifact,output_dir);
save(fullfile(output_dir,'nk_ee_irfs.mat'),'-struct','artifact','-v7.3');
fprintf('NK EE gain %.4g: %d/%d draws completed; RE output impact %.4g%%.\n', ...
    config.gain,artifact.status_counts.completed,config.draw_count, ...
    100*re(output_index,1));
end

function path=make_re_irf(plugin,horizon)
alm=plugin.plm_to_alm(plugin.re_plm);
path=zeros(numel(plugin.model.variable_names),horizon);
path(:,1)=alm.shock_impact(:,1);
for period=2:horizon
    path(:,period)=alm.transition*path(:,period-1);
end
end

function summary=summarize_paths(raw,re,probabilities)
ordered=sort(raw,1);
n=size(ordered,1);
summary=struct('learning_median',squeeze(median(raw,1)), ...
    'learning_low',squeeze(ordered(max(1,ceil(probabilities(1)*n)),:,:)), ...
    'learning_high',squeeze(ordered(min(n,ceil(probabilities(2)*n)),:,:)), ...
    're',re,'band_probabilities',probabilities);
end

function contract=reporting_contract(names)
percent_names={'output','consumption','investment','hours','capital','rk','wage'};
annualized_names={'inflation','interest'};
contract=struct('internal_coordinate','log_deviation', ...
    'percent_multiplier',100,'percent_variables',{intersect(percent_names,names,'stable')}, ...
    'annualized_percentage_point_multiplier',400, ...
    'annualized_variables',{intersect(annualized_names,names,'stable')});
end

function files=render_irfs(artifact,output_dir)
names={'output','consumption','investment','hours','inflation','interest'};
indices=zeros(size(names));
for j=1:numel(names)
    indices(j)=name_index(artifact.variable_names,names{j});
end
data=artifact.reported_summary;
periods=artifact.config.plot_periods;
fig=figure('Visible','off','Color','white','Position',[100 100 1100 780]);
cleanup=onCleanup(@() close(fig));
layout=tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for j=1:numel(names)
    row=indices(j);
    ax=nexttile(layout);
    fill(ax,[periods fliplr(periods)], ...
        [data.learning_low(row,periods) fliplr(data.learning_high(row,periods))], ...
        [0.85 0.85 0.85],'EdgeColor','none');
    hold(ax,'on');
    plot(ax,periods,data.learning_median(row,periods),'k-','LineWidth',1.5);
    plot(ax,periods,data.re(row,periods),'k--','LineWidth',1.5);
    title(ax,names{j}); xlabel(ax,'Quarters'); grid(ax,'on');
    if ismember(names{j},artifact.reporting.annualized_variables)
        ylabel(ax,'Annualized percentage points');
    else
        ylabel(ax,'Percent deviation');
    end
    xlim(ax,[periods(1) periods(end)]);
end
legend(nexttile(layout,1),{'25th–75th percentile','EE median','RE'}, ...
    'Location','best');
title(layout,sprintf('NK technology shock | EE gain %.4g | completed %d/%d', ...
    artifact.config.gain,artifact.status_counts.completed,artifact.config.draw_count));
pdf=fullfile(output_dir,'nk_ee_irfs.pdf');
png=fullfile(output_dir,'nk_ee_irfs.png');
exportgraphics(fig,pdf,'ContentType','vector');
exportgraphics(fig,png,'Resolution',250);
files={pdf,png};
clear cleanup
end

function reported=apply_reporting(summary,contract,names)
reported=summary;
fields={'learning_median','learning_low','learning_high','re'};
percent=ismember(names,contract.percent_variables);
annualized=ismember(names,contract.annualized_variables);
for j=1:numel(fields)
    values=reported.(fields{j});
    values(percent,:)=contract.percent_multiplier*values(percent,:);
    values(annualized,:)= ...
        contract.annualized_percentage_point_multiplier*values(annualized,:);
    reported.(fields{j})=values;
end
reported.units=struct('percent_deviation',{contract.percent_variables}, ...
    'annualized_percentage_points',{contract.annualized_variables});
end

function value=paired_termination(paired)
for field={'training','baseline','shocked'}
    path=paired.(field{1});
    if ~isempty(path) && path.status~="completed"
        value=path.termination;
        return
    end
end
value=struct();
end

function index=name_index(names,name)
index=find(strcmp(names,name),1);
assert(~isempty(index),'NKEEIR:MissingName','Model is missing %s.',name);
end

function validate_config(config)
required={'gain','random_seed','draw_count','training_periods','ir_periods', ...
    'plot_periods','band_probabilities','training_shock_standard_deviation', ...
    'impact_output_percent','explosion_magnitude_percent'};
assert(isstruct(config)&&isscalar(config)&&isempty(setxor(fieldnames(config),required.')), ...
    'NKEEIR:InvalidConfig','Use the complete NK EE IR configuration.');
positive_integer(config.random_seed,'random_seed');
positive_integer(config.draw_count,'draw_count');
positive_integer(config.training_periods,'training_periods');
positive_integer(config.ir_periods,'ir_periods');
assert(isrow(config.plot_periods)&&all(config.plot_periods>=1)&& ...
    all(config.plot_periods<=config.ir_periods),'NKEEIR:InvalidConfig', ...
    'plot_periods must index the IR horizon.');
assert(isequal(size(config.band_probabilities),[1 2])&& ...
    config.band_probabilities(1)>0&&config.band_probabilities(2)<1&& ...
    config.band_probabilities(1)<config.band_probabilities(2), ...
    'NKEEIR:InvalidConfig','band_probabilities must be ordered values in (0,1).');
positive_scalar(config.gain,'gain');
assert(config.gain<=1,'NKEEIR:InvalidConfig','gain must not exceed one.');
positive_scalar(config.training_shock_standard_deviation, ...
    'training_shock_standard_deviation');
positive_scalar(config.impact_output_percent,'impact_output_percent');
positive_scalar(config.explosion_magnitude_percent,'explosion_magnitude_percent');
end

function positive_integer(value,label)
assert(isnumeric(value)&&isscalar(value)&&isfinite(value)&&value>=1&& ...
    value==floor(value),'NKEEIR:InvalidConfig','%s must be a positive integer.',label);
end

function positive_scalar(value,label)
assert(isnumeric(value)&&isscalar(value)&&isfinite(value)&&value>0, ...
    'NKEEIR:InvalidConfig','%s must be positive and finite.',label);
end
