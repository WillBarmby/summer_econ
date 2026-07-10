function model = load_legacy_ep_model(param)
%% LOAD_LEGACY_EP_MODEL Populate the canonical interface from E&P matrices.

if nargin < 1
    cfg = ir_default_config();
    param = cfg.main.model_param;
end
[A,C,invA0,k_y,disc,invalid] = build_model_matrices(param);
assert(~invalid, 'Invalid E&P calibration.');
idx = ir_variable_indices();
names = {'rk','wage','bond','output','hours','caput','capital','mp', ...
    'investment','rk_sum','w_sum','consumption','gamma_x'};
n = numel(names);
A0 = inv(invA0);
model = struct();
model.name = 'Eusepi-Preston legacy';
model.backend = 'legacy';
model.variable_names = names;
model.shock_names = {'eps_x'};
model.equation_names = names;
model.current = A0;
model.lag = -A{5};
model.lead = -A{3};
model.shock = -C;
model.calibration = struct('param', param(:));
model.expectation_matrices = A;
model.inv_current = invA0;
model.forecast_horizon = k_y;
model.discounts = disc;
model.indices = idx;
[o0,oc,invalid] = REDS_SOLDS_Model_Sept_2009(param);
assert(~invalid);
[o0,oc] = REE_solve(o0,oc,A,C,invA0,k_y,disc);
[t0,tL,ts] = ALM_fun(A,C,invA0,o0,oc,k_y,disc);
model.re = struct('source','legacy','intercept',t0,'transition',tL, ...
    'shock_impact',ts,'plm_intercept',o0,'plm_transition',oc);
assert(size(model.current,1) == n);
validate_canonical_model(model);
end
