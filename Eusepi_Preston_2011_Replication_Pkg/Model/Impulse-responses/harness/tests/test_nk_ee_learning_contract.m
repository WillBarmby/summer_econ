function test_nk_ee_learning_contract()
%% TEST_NK_EE_LEARNING_CONTRACT Verify the primary NK EE specification.

root=fileparts(fileparts(mfilename('fullpath')));
model_path=fullfile(root,'models','nk_nonlinear_rotemberg_pricing.mod');
calibration=nk_model_calibration_config("iid_comparison");
model=load_dynare_71_first_order_model(model_path, ...
    'ParameterOverrides',calibration.parameter_overrides);
model=convert_first_order_to_log_deviations(model,model.variable_names);
config=nk_ee_learning_config(0.002);
[plugin,state]=make_dynare_ee_learning_plugin(model,config, ...
    model.re.shock_covariance(1,1));

assert(model.calibration.rho_technology==0);
assert(isequal(config.learned_outcomes, ...
    {'rk','consumption','inflation','capital'}));
assert(isequal(config.observed_but_excluded,{'eps_technology'}));
assert(config.update_timing=="decide_then_update");
assert(isequal(plugin.specification,config));

% RE initialization must be a fixed point of the structural PLM-to-ALM map.
plm=plugin.beliefs_to_plm(state);
alm=plugin.plm_to_alm(plm);
assert(max(abs(alm.intercept-plm.intercept))<1e-10);
assert(max(abs(alm.transition-plm.transition),[],'all')<1e-10);
assert(max(abs(alm.shock_impact-plugin.shock_impact),[],'all')<1e-10);

% Every declared forward-looking forecast must affect the NK actual law.
capital=find(strcmp(model.variable_names,'capital'),1);
for name={'rk','consumption','inflation'}
    changed=plm;
    row=find(strcmp(model.variable_names,name{1}),1);
    changed.transition(row,capital)=changed.transition(row,capital)+0.01;
    changed_alm=plugin.plm_to_alm(changed);
    assert(norm(changed_alm.transition-alm.transition,'fro')>1e-8, ...
        'NKEE:InactiveForecast','The %s forecast does not affect the ALM.',name{1});
end
fprintf('NK IID EE learning contract and RE initialization passed.\n');
end
