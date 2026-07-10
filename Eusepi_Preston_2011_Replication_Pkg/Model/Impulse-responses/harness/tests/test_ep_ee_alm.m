function test_ep_ee_alm()
%% TEST_EP_EE_ALM Validate one-step EE mapping separately from structural RE.

cfg=ir_default_config(); param=cfg.main.model_param; param(1)=0;
model=load_legacy_ep_model(param);
n=numel(model.variable_names);
rng(19);
for draw=1:8
    transition=randn(n)*0.015;
    intercept=randn(n,1)*0.002;
    plm=struct('intercept',intercept,'transition',transition);
    canonical=plm_to_alm_linear(model,plm);
    [t0,tL,ts]=ALM_fun(model.expectation_matrices,model.transformed_shock, ...
        model.inv_current,intercept,transition,model.forecast_horizon,model.discounts);
    assert(max(abs(canonical.intercept-t0))<1e-12);
    assert(max(abs(canonical.transition-tL),[],'all')<1e-12);
    assert(max(abs(canonical.shock_impact-ts),[],'all')<1e-12);
end
fprintf('E&P one-step EE PLM-to-ALM tests passed.\n');
end
