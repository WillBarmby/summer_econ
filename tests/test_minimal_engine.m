function test_minimal_engine()
%% TEST_MINIMAL_ENGINE Verify the generic PLM, ALM, RLS, and path contracts.

setup_project();
test_one_step_mapping();
test_jacobian_unpacking();
test_rls_update();

learning_model = scalar_learning_model();
policy = explosion_policy(1,1000);
run = simulate_learning(learning_model,zeros(1,8),0, ...
    learning_model.initial_beliefs,policy);
assert(run.status=="completed");
assert(isequal(size(run.native_path),[1 9]));
assert(run.learning_state.observations==8);

test_paired_restart(learning_model,policy);
test_failure_statuses(learning_model);
fprintf('Minimal generic learning engine passed.\n');
end

function test_one_step_mapping()
% The structural residual is 2*y_t-y_(t-1)+0.5*E_t[y_(t+1)]-3*eps_t=0.
model = struct('variable_names',{{'state'}},'current',2,'lag',-1, ...
    'lead',0.5,'shock',-3);
plm = struct('intercept',0,'transition',0.25);
alm = plm_to_alm_one_step(model,plm);
lhs = 2+0.5*0.25;
assert(abs(alm.intercept)<1e-14);
assert(abs(alm.transition-1/lhs)<1e-14);
assert(abs(alm.shock_impact-3/lhs)<1e-14);
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

function test_paired_restart(learning_model,policy)
paired = simulate_paired_irf(learning_model,zeros(1,8),zeros(1,5),1, ...
    0,learning_model.initial_beliefs,policy);
assert(paired.status=="completed");
assert(isequal(paired.baseline.native_path(:,1), ...
    paired.shocked.native_path(:,1)));
assert(abs(paired.native_irf(1,1)-learning_model.shock_impact)<1e-12);
end

function test_failure_statuses(learning_model)
explosive = simulate_learning(learning_model,1,0, ...
    learning_model.initial_beliefs,explosion_policy(1,1e-12));
assert(explosive.status=="explosive" && ...
    explosive.termination.criterion=="magnitude_limit");

beliefs = struct('coefficients',[0 0],'moment_matrix',zeros(2), ...
    'observations',0,'projection_events',0,'invalid',false);
config = struct('gain',struct('type','constant','value',0.5), ...
    'rcond_tolerance',1e-12,'project',[]);
% Use a singular moment matrix so the generic engine reports an invalid draw.
invalid = simulate_learning(set_learning_config(learning_model,config), ...
    0,0,beliefs,explosion_policy(1,1000));
assert(invalid.status=="invalid" && ...
    invalid.termination.criterion=="singular_moment_matrix");

singular_alm_model = learning_model;
singular_alm_model.plm_to_alm = @raise_singular_alm;
invalid_alm = simulate_learning(singular_alm_model,0,0, ...
    learning_model.initial_beliefs,explosion_policy(1,1000));
assert(invalid_alm.status=="invalid" && ...
    invalid_alm.termination.criterion=="singular_alm");

unstable_forecast_model = learning_model;
unstable_forecast_model.plm_to_alm = @raise_unstable_forecast;
invalid_forecast = simulate_learning(unstable_forecast_model,0,0, ...
    learning_model.initial_beliefs,explosion_policy(1,1000));
assert(invalid_forecast.status=="invalid" && ...
    invalid_forecast.termination.criterion=="unstable_forecast");
end

function learning_model = set_learning_config(learning_model,config)
learning_model.learning = config;
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

function value = explosion_policy(n,limit)
value = struct('magnitude_limit',limit,'reject_nonfinite',true, ...
    'variable_indices',1:n);
end

function learning_model = scalar_learning_model()
learning = struct('initial_coefficients',[0 0.5], ...
    'initial_moment_matrix',eye(2), ...
    'gain',struct('type','constant','value',0.25), ...
    'rcond_tolerance',1e-12,'project',[]);
learning_model = struct( ...
    'name','synthetic scalar model', ...
    'model',struct('variable_names',{{'state'}}, ...
    'shock_names',{{'eps'}},'equation_names',{{'state_equation'}}), ...
    'initial_beliefs',initialize_beliefs(learning), ...
    'learning',learning, ...
    'beliefs_to_plm',@scalar_beliefs_to_plm, ...
    'plm_to_alm',@scalar_plm_to_alm, ...
    'regressor',@(path,time) [1;path(1,time-1)], ...
    'outcome',@(path,time) path(1,time), ...
    're_plm',struct('intercept',0,'transition',0.5), ...
    'shock_impact',1,'specification',struct('name','synthetic'));
end

function plm = scalar_beliefs_to_plm(beliefs)
plm = struct('intercept',beliefs.coefficients(1), ...
    'transition',beliefs.coefficients(2));
end

function alm = scalar_plm_to_alm(plm)
alm = struct('intercept',plm.intercept,'transition',plm.transition, ...
    'shock_impact',1);
end
