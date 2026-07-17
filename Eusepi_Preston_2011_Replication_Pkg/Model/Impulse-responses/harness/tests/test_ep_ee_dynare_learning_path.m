function test_ep_ee_dynare_learning_path()
%% TEST_EP_EE_DYNARE_LEARNING_PATH Compare Dynare EE with the paper archive.
% This short test is intentionally stronger than an RE comparison: both
% implementations update beliefs along the same nonzero-shock learning path.

model_path=fullfile(fileparts(fileparts(mfilename('fullpath'))),'models', ...
    'ep_ee_paper.mod');
dynare_model=load_dynare_71_linear_model(model_path);
gain=0.002;
shock_scale=exp(-0.144);
archive_config=ep_ee_learning_config("archive",gain);
[dynare_plugin,dynare_state]=make_dynare_ee_learning_plugin( ...
    dynare_model,archive_config,shock_scale^2);

cfg=ir_default_config();
param=cfg.main.model_param;
param(1)=0;
param(6)=gain;
[legacy_plugin,legacy_state]=make_ep_learning_plugin(param,shock_scale^2);

rng(32,'twister');
shocks=shock_scale*randn(1,299);
dynare_policy=cfg.main.explosion_policy;
dynare_policy.variable_indices=1:10;
dynare_run=simulate_learning_path(dynare_plugin,shocks, ...
    zeros(10,1),dynare_state,dynare_policy);
legacy_run=simulate_learning_path(legacy_plugin,shocks, ...
    zeros(13,1),legacy_state,cfg.main.explosion_policy);

shared={'rk','wage','output','hours','caput','capital','consumption', ...
    'investment','gamma_x'};
[~,dynare_rows]=ismember(shared,dynare_model.variable_names);
[~,legacy_rows]=ismember(shared,legacy_plugin.model.variable_names);
assert(dynare_run.status=="completed" && legacy_run.status=="completed");
maximum=max(abs(dynare_run.native_path(dynare_rows,:) ...
    -legacy_run.native_path(legacy_rows,:)),[],'all');
assert(maximum<1e-10,'Dynare and archived EE paths differ by %.16g.',maximum);
fprintf('Dynare/archive EE learning-path parity passed; max difference %.3g.\n',maximum);
end
