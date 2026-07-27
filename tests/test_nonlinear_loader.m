function test_nonlinear_loader()
%% TEST_NONLINEAR_LOADER Verify NK analytical linearization and unit conversion.
% This test covers the complete boundary between nonlinear Dynare levels and
% the percentage-point canonical model consumed by adaptive learning.

root = setup_project();
model_path = fullfile(root,'models','nk_balanced_growth.mod');
model = load_nonlinear_dynare_model(model_path, ...
    'DeviationScales',struct('gamma_x',0.01));

%% The loader must preserve names and the declared twelve-equation ordering.
expected_variables = {'rk','wage','output','hours','consumption','investment', ...
    'capital','inflation','nominal_rate','marginal_cost','risk_premium','gamma_x'};
expected_equations = {'capital_demand','labor_supply','production', ...
    'labor_demand','capital_euler','resource_constraint', ...
    'capital_accumulation','rotemberg_pricing','bond_euler', ...
    'monetary_policy','technology_growth','risk_premium'};
assert(isequal(model.variable_names,expected_variables));
assert(isequal(model.equation_names,expected_equations));
assert(strcmp(model.backend,'dynare-7.1-nonlinear-first-order'));

%% Dynare's nonlinear steady state must satisfy the documented identities.
calibration = model.calibration;
steady = model.transformation.level_steady_state;
index = @(name) find(strcmp(model.variable_names,name),1);
tolerance = 1e-10;
assert(max(abs(model.dynare.steady_state_residual))<tolerance);
assert(abs(steady(index('hours'))-1/3)<tolerance);
assert(abs(steady(index('marginal_cost'))- ...
    (calibration.theta-1)/calibration.theta)<tolerance);
assert(abs(steady(index('rk'))- ...
    (calibration.gamma_bar/calibration.beta-(1-calibration.delta)))<tolerance);
assert(abs(steady(index('nominal_rate'))- ...
    calibration.gamma_bar*calibration.pi_bar/ ...
    (calibration.beta*calibration.risk_premium_bar))<tolerance);

%% One canonical unit must mean one percentage point for every variable.
scales = model.transformation.deviation_scales;
positive = steady>0;
assert(max(abs(scales(positive)-steady(positive)/100))<tolerance);
assert(abs(scales(index('gamma_x'))-0.01)<tolerance);

%% The transformed structural system must reproduce Dynare's own RE law.
% Substituting the RE PLM into the one-step expectations mapping should return
% the same transition and shock matrices. This jointly checks Jacobian column
% ordering, signs, timing, and the level-to-percentage transformation.
[transition,shock] = extract_re_law(model);
re_plm = struct('intercept',zeros(numel(model.variable_names),1), ...
    'transition',transition);
alm = plm_to_alm_one_step(model,re_plm);
assert(max(abs(alm.transition-transition),[],'all')<1e-10);
assert(max(abs(alm.shock_impact-shock),[],'all')<1e-10);
assert(abs(shock(index('gamma_x'),1)-1)<tolerance);
assert(max(abs(shock(:,2)))<tolerance); % dormant risk-premium shock
assert(max(abs(eig(transition)))<1);

%% Parameter overrides must pass through the Dynare macro layer.
persistent_model = load_nonlinear_dynare_model(model_path, ...
    'ParameterOverrides',struct('rho_x',0.25), ...
    'DeviationScales',struct('gamma_x',0.01));
assert(abs(persistent_model.calibration.rho_x-0.25)<tolerance);

fprintf('Nonlinear NK Dynare loader passed analytical and unit checks.\n');
end
