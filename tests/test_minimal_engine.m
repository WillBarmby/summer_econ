function test_minimal_engine()
%% TEST_MINIMAL_ENGINE Verify the extracted engine against frozen references.

root = setup_project();
reference = load(fullfile(root,'tests','fixtures','ep_engine_reference.mat'));
reference = reference.fixture;
override = struct('gamma_bar',reference.gamma_bar);
ee_model = load_linear_dynare_model(fullfile(root,'models','ep_rbc_ee.mod'), ...
    'ParameterOverrides',override);
ih_model = load_linear_dynare_model(fullfile(root,'models','ep_rbc_ih.mod'), ...
    'ParameterOverrides',override);

compare_model(ee_model,reference.ee);
compare_model(ih_model,reference.ih);
ee = build_ee_learning_model(ee_model,ee_spec(reference.gain), ...
    reference.shock_standard_deviation^2);
ih = build_ep_ih_learning_model(ih_model,ih_spec(reference.gain), ...
    reference.shock_standard_deviation^2);
assert_learning_contract(ee);
assert_learning_contract(ih);
policy_ee = policy(numel(ee_model.variable_names),1000);
policy_ih = policy(numel(ih_model.variable_names),1000);
ee_run = simulate_learning(ee,reference.shocks, ...
    zeros(numel(ee_model.variable_names),1),ee.initial_beliefs,policy_ee);
ih_run = simulate_learning(ih,reference.shocks, ...
    zeros(numel(ih_model.variable_names),1),ih.initial_beliefs,policy_ih);
assert(ee_run.status=="completed" && ih_run.status=="completed");
assert(max(abs(ee_run.native_path-reference.ee.native_path),[],'all')<1e-10);
assert(max(abs(ih_run.native_path-reference.ih.native_path),[],'all')<1e-10);
assert(max(abs(ee_run.learning_state.coefficients- ...
    reference.ee.final_coefficients),[],'all')<1e-10);
assert(max(abs(ih_run.learning_state.coefficients- ...
    reference.ih.final_coefficients),[],'all')<1e-10);

test_rls_update();
test_jacobian_unpacking();
test_paired_restart(ee,policy_ee);
test_failure_statuses(ee);
fprintf('Minimal Dynare and E&P learning engine passed reference parity.\n');
end

function test_jacobian_unpacking()
dynare_model = struct('endo_nbr',2,'exo_nbr',1,'exo_det_nbr',0, ...
    'eq_nbr',2,'lead_lag_incidence',[1 0;2 3;0 4]);
jacobian = [1 0 2 3 0 4 5;6 0 7 8 0 9 10];
matrices = unpack_dynare_jacobian(jacobian,dynare_model);
assert(isequal(matrices.lag,[1 0;6 0]));
assert(isequal(matrices.current,[2 3;7 8]));
assert(isequal(matrices.lead,[0 4;0 9]));
assert(isequal(matrices.shock,[5;10]));
end

function compare_model(model,reference)
assert(isequal(model.variable_names,reference.variable_names));
assert(isequal(model.equation_names,reference.equation_names));
for field = {'current','lag','lead','shock'}
    assert(max(abs(model.(field{1})-reference.(field{1})),[],'all')<1e-12);
end
[transition,shock] = extract_re_law(model);
assert(max(abs(transition-reference.re_transition),[],'all')<1e-12);
assert(max(abs(shock-reference.re_shock),[],'all')<1e-12);
end

function assert_learning_contract(value)
required = {'model','initial_beliefs','beliefs_to_plm','plm_to_alm', ...
    'regressor','outcome','re_plm','shock_impact','specification'};
assert(all(isfield(value,required)));
end

function test_rls_update()
beliefs = struct('coefficients',[1 2],'moment_matrix',eye(2), ...
    'observations',0,'projection_events',0,'invalid',false);
config = struct('gain',struct('type','constant','value',0.25), ...
    'rcond_tolerance',1e-12,'project',[]);
x = [1;2];
y = 8;
new_moment = eye(2)+0.25*(x*x'-eye(2));
expected = beliefs.coefficients+0.25* ...
    (y-beliefs.coefficients*x)*(new_moment\x)';
[updated,diagnostic] = update_beliefs_rls(beliefs,x,y,config);
assert(max(abs(updated.coefficients-expected),[],'all')<1e-14);
assert(max(abs(updated.moment_matrix-new_moment),[],'all')<1e-14);
assert(diagnostic.prediction_error==3 && ~diagnostic.projected);
end

function test_paired_restart(learning_model,explosion_policy)
training = zeros(1,8);
future = zeros(1,5);
impulse = 1;
n = numel(learning_model.model.variable_names);
paired = simulate_paired_irf(learning_model,training,future,impulse, ...
    zeros(n,1),learning_model.initial_beliefs,explosion_policy);
assert(paired.status=="completed");
assert(isequal(paired.baseline.native_path(:,1), ...
    paired.shocked.native_path(:,1)));
assert(max(abs(paired.native_irf(:,1)-learning_model.shock_impact), ...
    [],'all')<1e-12);
end

function test_failure_statuses(learning_model)
n = numel(learning_model.model.variable_names);
explosive = simulate_learning(learning_model,1,zeros(n,1), ...
    learning_model.initial_beliefs,policy(n,1e-12));
assert(explosive.status=="explosive" && ...
    explosive.termination.criterion=="magnitude_limit");

beliefs = struct('coefficients',0,'moment_matrix',0,'observations',0, ...
    'projection_events',0,'invalid',false);
config = struct('gain',struct('type','constant','value',0.5), ...
    'rcond_tolerance',1e-12,'project',[]);
[beliefs,~] = update_beliefs_rls(beliefs,0,0,config);
assert(beliefs.invalid);

initial = struct('coefficients',0,'moment_matrix',0,'observations',0, ...
    'projection_events',0,'invalid',false);
singular_model = struct('beliefs_to_plm',@(state) struct( ...
    'intercept',0,'transition',0),'plm_to_alm',@(plm) struct( ...
    'intercept',0,'transition',0,'shock_impact',0), ...
    'regressor',@(path,time) 0,'outcome',@(path,time) 0, ...
    'learning',config);
invalid = simulate_learning(singular_model,0,0,initial,policy(1,1000));
assert(invalid.status=="invalid" && ...
    invalid.termination.criterion=="singular_moment_matrix");

singular_alm_model = singular_model;
singular_alm_model.plm_to_alm = @(plm) raise_singular_alm(plm);
invalid_alm = simulate_learning(singular_alm_model,0,0,initial,policy(1,1000));
assert(invalid_alm.status=="invalid" && ...
    invalid_alm.termination.criterion=="singular_alm");

unstable_forecast_model = singular_model;
unstable_forecast_model.plm_to_alm = @(plm) raise_unstable_forecast(plm);
invalid_forecast = simulate_learning(unstable_forecast_model,0,0,initial, ...
    policy(1,1000));
assert(invalid_forecast.status=="invalid" && ...
    invalid_forecast.termination.criterion=="unstable_forecast");
end

function alm = raise_singular_alm(~)
error('EPResearch:SingularAlm','Deliberate singular-ALM test fixture.');
alm = struct(); %#ok<UNRCH>
end

function alm = raise_unstable_forecast(~)
error('EPResearch:UnstableForecast', ...
    'Deliberate unstable-forecast test fixture.');
alm = struct(); %#ok<UNRCH>
end

function value = policy(n,limit)
value = struct('magnitude_limit',limit,'reject_nonfinite',true, ...
    'variable_indices',1:n);
end

function value = ee_spec(gain)
value = struct('variant',"paper", ...
    'learned_outcomes',{{'rk','consumption','capital'}}, ...
    'regressors',{{'constant','capital_lag'}},'state_variable','capital', ...
    'observed_but_excluded',{{'eps_x'}}, ...
    'gain',struct('type','constant','value',gain,'offset',500), ...
    'initialization',"dynare_re",'update_timing',"decide_then_update", ...
    'projection',struct('outcome','capital','absolute_limit',0.99, ...
    'action',"reject_update"));
end

function value = ih_spec(gain)
value = struct('formulation',"infinite_horizon", ...
    'learned_outcomes',{{'rk','wage','capital'}}, ...
    'regressors',{{'constant','capital_lag'}},'state_variable','capital', ...
    'observed_but_excluded',{{'eps_x'}}, ...
    'forecast_targets',{{'rk','wage'}}, ...
    'present_value_variables',{{'rk_sum','w_sum'}}, ...
    'present_value_equations',{{'capital_pv','wage_pv'}}, ...
    'decision_equation','ih_consumption', ...
    'decision_forecast_targets',{{'gamma_x','rk','wage'}}, ...
    'gain',struct('type','constant','value',gain,'offset',500), ...
    'feedback',true,'update_timing',"decide_then_update", ...
    'initialization',"dynare_re",'rcond_tolerance',1.0856345e-10, ...
    'projection',struct('outcome','capital','regressor','capital_lag', ...
    'absolute_limit',0.99,'action',"reject_update"));
end
