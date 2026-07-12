function test_ep_learning_path()
%% TEST_EP_LEARNING_PATH Complete generic-versus-legacy learning path parity.

cfg=ir_default_config(); param=cfg.main.model_param;
[plugin,state]=make_ep_learning_plugin(param,cfg.main.shock_scale^2);
rng(31); eps=randn(1,300);
generic=simulate_learning_path(plugin,cfg.main.shock_scale*eps(:,1:end-1), ...
    zeros(13,1),state,cfg.main.explosion_policy);
[legacy,~,~,~,~,~,~,~,~,~,~,~,~,~,~,invalid]=simulate_model_paths( ...
    param,cfg.main.shock_scale,true,true,false,false,true,1,0,0,0,0,0,1,eps, ...
    cfg.main.explosion_policy);
assert(~invalid && ~generic.invalid);
assert(max(abs(generic.native_path-legacy),[],'all')<1e-10, ...
    'Generic E&P learning path differs from legacy simulation.');
fprintf('Complete E&P learning-path parity test passed.\n');
end
