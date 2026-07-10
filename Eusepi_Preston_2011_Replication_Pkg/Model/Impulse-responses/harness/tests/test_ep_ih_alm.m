function test_ep_ih_alm()
%% TEST_EP_IH_ALM Validate complete direct IH ALM against legacy ALM_fun.

cfg=ir_default_config(); model=load_legacy_ep_model(cfg.main.model_param);
n=numel(model.variable_names); beta=model.discounts(1); rng(23);
for draw=1:8
    C=randn(n)*0.015; mu=randn(n,1)*0.002;
    plm=struct('intercept',mu,'transition',C);
    F0=zeros(n,1); F1=zeros(n);
    for j=1:n
        target=zeros(1,n); target(j)=1/beta;
        value=evaluate_var_expectation(plm,make_expectation_spec('ih',target,[1 Inf],beta));
        F0(j)=value.intercept; F1(j,:)=value.coefficients;
    end
    A=model.expectation_matrices; invA0=model.inv_current;
    raw0=invA0*(A{1}+A{3}*mu+A{4}*F0);
    contemporaneous=invA0*(A{3}*C+A{4}*F1);
    lhs=eye(n)-contemporaneous;
    direct0=lhs\raw0;
    directL=lhs\(invA0*A{5});
    directS=lhs\model.transformed_shock;
    [t0,tL,ts]=ALM_fun(A,model.transformed_shock,invA0,mu,C, ...
        model.forecast_horizon,model.discounts);
    assert(max(abs(direct0-t0))<1e-11);
    assert(max(abs(directL-tL),[],'all')<1e-11);
    assert(max(abs(directS-ts),[],'all')<1e-11);
end
fprintf('E&P complete IH expectation/ALM tests passed.\n');
end
