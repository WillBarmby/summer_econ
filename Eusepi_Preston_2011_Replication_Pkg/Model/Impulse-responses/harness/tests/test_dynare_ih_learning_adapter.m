function test_dynare_ih_learning_adapter()
%% TEST_DYNARE_IH_LEARNING_ADAPTER Require parity under arbitrary beliefs.

model_dir=fileparts(fileparts(mfilename('fullpath')));
dynare_model=load_dynare_71_linear_model(fullfile(model_dir,'models','ep13_ih_re_linear.mod'));
experiment=make_ir_config();
legacy=load_legacy_ep_model(experiment.main.model_param);
[plugin,~]=make_dynare_ih_learning_plugin(dynare_model,ep_ih_learning_config(), ...
    experiment.main.shock_scale^2);

% Matching only the RE solution is insufficient: an omitted subjective
% forecast can vanish under RE and still change adaptive-learning dynamics.
rng(23);
for draw=1:8
    transition=randn(13)*0.015;
    intercept=randn(13,1)*0.002;
    actual=plugin.plm_to_alm(struct('intercept',intercept,'transition',transition));
    [expected0,expectedL,expectedS]=ALM_fun(legacy.expectation_matrices, ...
        legacy.transformed_shock,legacy.inv_current,intercept,transition, ...
        legacy.forecast_horizon,legacy.discounts);
    assert(max(abs(actual.intercept-expected0))<1e-11);
    assert(max(abs(actual.transition-expectedL),[],'all')<1e-11);
    assert(max(abs(actual.shock_impact-expectedS),[],'all')<1e-11);
end
fprintf('Dynare-driven E&P IH arbitrary-belief parity tests passed.\n');
end
