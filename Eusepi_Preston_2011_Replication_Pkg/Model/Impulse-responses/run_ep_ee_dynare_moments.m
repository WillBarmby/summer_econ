function artifact = run_ep_ee_dynare_moments(config)
%% RUN_EP_EE_DYNARE_MOMENTS Run paper-style EE using Dynare 7.1 matrices.

if nargin==0, config=ep_ee_paper_config(); end
model_path=fullfile(fileparts(mfilename('fullpath')),'harness','models', ...
    'ep_ee_paper.mod');
model=load_dynare_71_linear_model(model_path);
learning_config=ep_ee_learning_config("paper",config.gain);
[plugin,initial_learning]=make_dynare_ee_learning_plugin( ...
    model,learning_config,config.shock_scale^2);
base=ir_default_config();
policy=base.main.explosion_policy;
policy.variable_indices=1:numel(model.variable_names);
rng(config.seed,'twister');
moments=NaN(8,config.n_draws);
statuses=strings(1,config.n_draws);
for draw=1:config.n_draws
    innovations=randn(1,config.path_length);
    run=simulate_learning_path(plugin,config.shock_scale*innovations(1:end-1), ...
        zeros(numel(model.variable_names),1),initial_learning,policy);
    statuses(draw)=run.status;
    if run.status=="completed"
        [path13,forecast13]=map_to_archive_rows(run,model.variable_names);
        result=calculate_ep_archive_moments(path13,forecast13,config);
        moments(:,draw)=result.table5_values;
    end
end
completed=statuses=="completed";
names={'sigma_y','sigma_c_over_y','sigma_i_over_y','sigma_h_over_y', ...
    'rho_dc','rho_dy','rho_di','rho_wage_fe'};
artifact=struct('backend',model.backend,'dynare_version',model.dynare.version, ...
    'config',config,'learning_specification',learning_config, ...
    'moment_names',{names},'draw_moments',moments, ...
    'mean_moments',mean(moments(:,completed),2,'omitnan'),'statuses',statuses, ...
    'status_counts',struct('completed',sum(completed), ...
    'explosive',sum(statuses=="explosive"),'invalid',sum(statuses=="invalid")));
fprintf('Dynare E&P EE gain %.4g: %d/%d draws completed.\n',config.gain, ...
    artifact.status_counts.completed,config.n_draws);
disp(table(string(names(:)),artifact.mean_moments,'VariableNames',{'moment','mean'}));
end

function [path13,forecast13]=map_to_archive_rows(run,names)
idx=ir_variable_indices();
path13=zeros(13,size(run.native_path,2));
forecast13=NaN(13,size(run.one_step_forecasts,2));
shared={'rk','wage','output','hours','caput','capital','investment', ...
    'consumption','gamma_x'};
for j=1:numel(shared)
    source=find(strcmp(names,shared{j}),1);
    destination=idx.(shared{j});
    path13(destination,:)=run.native_path(source,:);
    forecast13(destination,:)=run.one_step_forecasts(source,:);
end
end
