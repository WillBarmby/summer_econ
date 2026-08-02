function artifact = run_ep_ee_specification_comparison(config)
%% RUN_EP_EE_SPECIFICATION_COMPARISON Matched RE/EE Monte Carlo with CIs.

validate_config(config);
moment_names={'sigma_y','sigma_c_over_y','sigma_i_over_y','sigma_h_over_y', ...
    'rho_dc','rho_dy','rho_di','rho_wage_fe'};
variants=string(config.variants);
nV=numel(variants); nG=numel(config.gains); nS=numel(config.sigmas);
nD=config.n_draws;
moments=NaN(8,nD,nV,nG,nS);
distance=NaN(nD,nV,nG,nS);
statuses=strings(nD,nV,nG,nS);
termination_period=NaN(nD,nV,nG,nS);
final_plm=NaN(4,nD,nV,nG,nS);
stability_roots=NaN(2,nD,nV,nG,nS);

for s=1:nS
    model=load_ep_ee_dynare_model(config.sigmas(s));
    policy=ir_default_config().main.explosion_policy;
    policy.variable_indices=1:numel(model.variable_names);
    wage=find(strcmp(model.variable_names,'wage'),1);
    consumption=find(strcmp(model.variable_names,'consumption'),1);
    capital=find(strcmp(model.variable_names,'capital'),1);
    for g=1:nG
        plugins=cell(1,nV); initials=cell(1,nV);
        for v=2:nV
            learning=ep_ee_learning_config(variants(v),config.gains(g));
            [plugins{v},initials{v}]=make_dynare_ee_learning_plugin( ...
                model,learning,config.shock_scale^2);
        end
        re_plm=plugins{2}.re_plm;
        rng(config.seed,'twister');
        for draw=1:nD
            shocks=config.shock_scale*randn(1,config.path_length-1);
            [re_path,re_forecasts]=simulate_re(model,re_plm,shocks);
            re=struct('native_path',re_path,'one_step_forecasts',re_forecasts);
            runs=cell(1,nV); runs{1}=re;
            statuses(draw,1,g,s)="completed";
            for v=2:nV
                runs{v}=simulate_learning_path(plugins{v},shocks,zeros(10,1), ...
                    initials{v},policy);
                statuses(draw,v,g,s)=runs{v}.status;
                termination_period(draw,v,g,s)=runs{v}.termination.period;
            end
            retained=config.sample_start+1:config.path_length;
            for v=1:nV
                if statuses(draw,v,g,s)~="completed", continue; end
                [path13,forecast13]=map_to_archive_rows(runs{v},model.variable_names);
                calculated=calculate_ep_archive_moments(path13,forecast13,config);
                moments(:,draw,v,g,s)=calculated.table5_values;
                if v>1
                    distance(draw,v,g,s)=rms_difference( ...
                        runs{v}.native_path(:,retained),re_path(:,retained));
                    plm=plugins{v}.beliefs_to_plm(runs{v}.learning_state);
                    roots=[max(runs{v}.plm_stability_root,[],'omitnan'); ...
                        max(runs{v}.alm_stability_root,[],'omitnan')];
                else
                    distance(draw,v,g,s)=0;
                    plm=re_plm;
                    alm=plm_to_alm_linear(model,re_plm);
                    roots=[max(abs(eig(re_plm.transition)));alm.stability_root];
                end
                final_plm(:,draw,v,g,s)=[plm.intercept(consumption); ...
                    plm.transition(consumption,capital);plm.intercept(wage); ...
                    plm.transition(wage,capital)];
                stability_roots(:,draw,v,g,s)=roots;
            end
            if mod(draw,max(1,min(100,floor(nD/10))))==0 || draw==nD
                fprintf('sigma %.3g gain %.3g: %d/%d draws\n', ...
                    config.sigmas(s),config.gains(g),draw,nD);
            end
        end
    end
end

[moment_summary,status_summary]=summarize_results(moments,distance,statuses, ...
    config,variants,moment_names);
draw_data=struct('moments',moments,'distance_from_re',distance, ...
    'statuses',statuses,'termination_period',termination_period, ...
    'final_plm',final_plm,'stability_roots',stability_roots);
artifact=struct('config',config,'moment_names',{moment_names}, ...
    'plm_diagnostic_names',{{'consumption_intercept','consumption_capital_slope', ...
    'wage_intercept','wage_capital_slope'}},'draw_data',draw_data, ...
    'moment_summary',moment_summary,'status_summary',status_summary);
write_artifacts(artifact);
end

function validate_config(config)
required={'n_draws','seed','gains','sigmas','variants','bootstrap_reps', ...
    'bootstrap_seed','output_file','path_length','sample_start','hp_lambda', ...
    'gamma_bar','shock_scale'};
assert(isstruct(config) && isscalar(config) && ...
    isempty(setxor(fieldnames(config),required.')), ...
    'EPEE:InvalidComparisonConfig','Comparison configuration is incomplete.');
assert(config.n_draws>=1 && config.n_draws==fix(config.n_draws));
assert(isequal(string(config.variants),["RE" "archive" "wage_proxy" "paper"]));
assert(~isempty(config.output_file),'EPEE:OutputRequired','output_file is required.');
end

function [path,forecasts]=simulate_re(model,plm,shocks)
alm=plm_to_alm_linear(model,plm);
T=size(shocks,2)+1; n=numel(model.variable_names);
path=zeros(n,T); forecasts=NaN(n,T);
for t=2:T
    path(:,t)=alm.intercept+alm.transition*path(:,t-1) ...
        +alm.shock_impact*shocks(:,t-1);
    forecasts(:,t)=plm.intercept+plm.transition*path(:,t);
end
end

function [path13,forecast13]=map_to_archive_rows(run,names)
idx=ir_variable_indices();
path13=zeros(13,size(run.native_path,2));
forecast13=NaN(13,size(run.one_step_forecasts,2));
shared={'rk','wage','output','hours','caput','capital','investment', ...
    'consumption','gamma_x'};
for j=1:numel(shared)
    source=find(strcmp(names,shared{j}),1); destination=idx.(shared{j});
    path13(destination,:)=run.native_path(source,:);
    forecast13(destination,:)=run.one_step_forecasts(source,:);
end
end

function value=rms_difference(x,y)
d=x-y; value=sqrt(mean(d(:).^2));
end

function [moments_table,status_table]=summarize_results(values,distance,statuses, ...
    config,variants,moment_names)
moment_rows=cell(0,13); status_rows=cell(0,9);
rng(config.bootstrap_seed,'twister');
for s=1:numel(config.sigmas)
    for g=1:numel(config.gains)
        for v=1:numel(variants)
            status=statuses(:,v,g,s);
            completed=status=="completed"; explosive=status=="explosive";
            invalid=status=="invalid";
            [completion_low,completion_high]=wilson(sum(completed),numel(status));
            status_rows(end+1,:)={config.sigmas(s),config.gains(g),variants(v), ...
                sum(completed),sum(explosive),sum(invalid),mean(completed), ...
                completion_low,completion_high}; %#ok<AGROW>
            for m=1:numel(moment_names)
                x=squeeze(values(m,:,v,g,s))'; x=x(completed);
                average=mean(x,'omitnan'); se=std(x,0,'omitnan')/sqrt(numel(x));
                if v==1
                    delta=zeros(size(x)); paired_count=numel(x);
                else
                    re=squeeze(values(m,:,1,g,s))';
                    common=completed & isfinite(re) & isfinite(squeeze(values(m,:,v,g,s))');
                    delta=squeeze(values(m,common,v,g,s))'-re(common);
                    paired_count=sum(common);
                end
                [lower,upper]=bootstrap_mean_ci(delta,config.bootstrap_reps);
                moment_rows(end+1,:)={config.sigmas(s),config.gains(g),variants(v), ...
                    string(moment_names{m}),average,se,average-1.96*se, ...
                    average+1.96*se,mean(delta,'omitnan'),lower,upper, ...
                    paired_count,mean(distance(:,v,g,s),'omitnan')}; %#ok<AGROW>
            end
        end
    end
end
moments_table=cell2table(moment_rows,'VariableNames',{'sigma','gain', ...
    'specification','moment','mean','monte_carlo_se','mean_ci_low','mean_ci_high', ...
    'paired_difference_from_re','paired_ci_low','paired_ci_high', ...
    'paired_draws','rms_path_distance_from_re'});
status_table=cell2table(status_rows,'VariableNames',{'sigma','gain', ...
    'specification','completed','explosive','invalid','completion_rate', ...
    'completion_ci_low','completion_ci_high'});
end

function [lower,upper]=bootstrap_mean_ci(x,reps)
x=x(isfinite(x));
if isempty(x), lower=NaN; upper=NaN; return; end
boot=NaN(reps,1); n=numel(x);
for b=1:reps
    boot(b)=mean(x(randi(n,n,1)));
end
boot=sort(boot);
lower=boot(max(1,round(.025*reps)));
upper=boot(min(reps,round(.975*reps)));
end

function [lower,upper]=wilson(successes,total)
z=1.96; p=successes/total; denominator=1+z^2/total;
center=(p+z^2/(2*total))/denominator;
radius=z/denominator*sqrt(p*(1-p)/total+z^2/(4*total^2));
lower=max(0,center-radius); upper=min(1,center+radius);
end

function write_artifacts(artifact)
[directory,name,extension]=fileparts(artifact.config.output_file);
assert(strcmp(extension,'.mat'),'EPEE:OutputExtension','output_file must end in .mat.');
if ~isfolder(directory), mkdir(directory); end
save(artifact.config.output_file,'artifact','-v7.3');
writetable(artifact.moment_summary,fullfile(directory,[name '_moments.csv']));
writetable(artifact.status_summary,fullfile(directory,[name '_statuses.csv']));
fid=fopen(fullfile(directory,[name '.md']),'w');
assert(fid>=0); cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'# Matched E&P EE Comparison\n\n');
fprintf(fid,'Draws per scenario: %d. Seed: %d. Bootstrap replications: %d.\n\n', ...
    artifact.config.n_draws,artifact.config.seed,artifact.config.bootstrap_reps);
fprintf(fid,'## Completion status\n\n');
fprintf(fid,'| Sigma | Gain | Specification | Completed | Explosive | Invalid | Rate | 95%% CI |\n');
fprintf(fid,'|---:|---:|---|---:|---:|---:|---:|---:|\n');
for j=1:height(artifact.status_summary)
    r=artifact.status_summary(j,:);
    fprintf(fid,'| %.3g | %.3g | %s | %d | %d | %d | %.4f | [%.4f, %.4f] |\n', ...
        r.sigma,r.gain,r.specification,r.completed,r.explosive,r.invalid, ...
        r.completion_rate,r.completion_ci_low,r.completion_ci_high);
end
fprintf(fid,'\nSee `%s_moments.csv` for moment means and paired confidence intervals.\n',name);
end
