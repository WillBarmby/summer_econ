function test_dynare_ih_learning_adapter()
%% TEST_DYNARE_IH_LEARNING_ADAPTER Require parity under arbitrary beliefs.

model_dir=fileparts(fileparts(mfilename('fullpath')));
dynare_model=load_dynare_71_linear_model(fullfile(model_dir,'models','ep13_ih_re_linear.mod'));
experiment=make_ir_config();
legacy=load_legacy_ep_model(experiment.main.model_param);
learning_config=ep_ih_learning_config();
assert(isequal(learning_config.learned_outcomes,{'rk','wage','capital'}), ...
    'The production PLM must match paper equations (8)-(10).');
[plugin,~]=make_dynare_ih_learning_plugin(dynare_model,learning_config, ...
    experiment.main.shock_scale^2);
assert_contract_rejected(dynare_model,experiment.main.shock_scale^2, ...
    'feedback',false,'EPIH:InvalidFeedback');
assert_contract_rejected(dynare_model,experiment.main.shock_scale^2, ...
    'update_timing',"update_then_decide",'EPIH:InvalidUpdateTiming');
assert_contract_rejected(dynare_model,experiment.main.shock_scale^2, ...
    'observed_but_excluded',{'missing_shock'},'EPIH:MissingName');

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

% The complete recursive-learning path must also preserve legacy timing,
% initialization, and RLS feedback—not just the one-period ALM mapping.
rng(31); innovations=randn(1,300);
generic=simulate_learning_path(plugin,experiment.main.shock_scale*innovations(1:end-1), ...
    zeros(13,1),initialize_learning_state(plugin.learning), ...
    experiment.main.explosion_policy);
[legacy_path,~,~,~,~,~,~,~,~,~,~,~,~,~,~,invalid]=simulate_model_paths( ...
    experiment.main.model_param,experiment.main.shock_scale,true,true,false,false, ...
    true,1,0,0,0,0,0,1,innovations,experiment.main.explosion_policy);
assert(~invalid && generic.status=="completed");
assert(max(abs(generic.native_path-legacy_path),[],'all')<1e-10);
fprintf('Dynare-driven E&P IH arbitrary-belief parity tests passed.\n');
end

function assert_contract_rejected(model,variance,field,value,identifier)
config=ep_ih_learning_config(); config.(field)=value;
try
    make_dynare_ih_learning_plugin(model,config,variance);
    error('Test:ExpectedFailure','Invalid IH contract was accepted.');
catch exception
    assert(strcmp(exception.identifier,identifier));
end
end
