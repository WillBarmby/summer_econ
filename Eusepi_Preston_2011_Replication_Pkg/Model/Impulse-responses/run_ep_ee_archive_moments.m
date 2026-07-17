function artifact = run_ep_ee_archive_moments(config)
%% RUN_EP_EE_ARCHIVE_MOMENTS Simulate archive-compatible E&P EE moments.
% Call with no input for explicit, reproducible defaults. Reduce n_draws
% while developing; the historical exercise used 5,000 successful draws.

if nargin==0
    config=ep_ee_archive_config();
end
validate_config(config);
base=ir_default_config();
param=base.main.model_param;
param(1)=0;
param(6)=config.gain;
[plugin,initial_learning]=make_ep_learning_plugin(param,config.shock_scale^2);

rng(config.seed,'twister');
moments=NaN(8,config.n_draws);
statuses=strings(1,config.n_draws);
for draw=1:config.n_draws
    innovations=randn(1,config.path_length);
    run=simulate_learning_path(plugin,config.shock_scale*innovations(1:end-1), ...
        zeros(13,1),initial_learning,base.main.explosion_policy);
    statuses(draw)=run.status;
    if run.status=="completed"
        computed=calculate_ep_archive_moments(run.native_path, ...
            run.one_step_forecasts,config);
        moments(:,draw)=computed.table5_values;
    end
end

completed=statuses=="completed";
artifact=struct('config',config,'parameter_vector',param,'moment_names', ...
    {computed_names()},'draw_moments',moments,'mean_moments', ...
    mean(moments(:,completed),2,'omitnan'),'statuses',statuses, ...
    'status_counts',struct('completed',sum(completed), ...
    'explosive',sum(statuses=="explosive"),'invalid',sum(statuses=="invalid")));
fprintf('E&P EE gain %.4g: %d/%d draws completed.\n',config.gain, ...
    artifact.status_counts.completed,config.n_draws);
disp(table(string(artifact.moment_names(:)),artifact.mean_moments, ...
    'VariableNames',{'moment','mean'}));
end

function validate_config(config)
required={'gain','n_draws','seed','path_length','sample_start', ...
    'hp_lambda','gamma_bar','shock_scale'};
assert(isstruct(config) && isscalar(config) && isempty(setxor(fieldnames(config),required.')), ...
    'EPMoments:InvalidConfig','Use the documented complete configuration.');
assert(config.gain>0 && config.n_draws>=1 && config.n_draws==fix(config.n_draws) ...
    && config.path_length>=4 && config.path_length==fix(config.path_length), ...
    'EPMoments:InvalidConfig','Gain, draw count, or path length is invalid.');
end

function names=computed_names()
names={'sigma_y','sigma_c_over_y','sigma_i_over_y','sigma_h_over_y', ...
    'rho_dc','rho_dy','rho_di','rho_wage_fe'};
end
