function test_nk_ee_specification()
%% TEST_NK_EE_SPECIFICATION Compile and exercise the proposed NK EE contract.
% This is deliberately a short deterministic development test, not a claim
% about the final Monte Carlo experiment or its economic results.

root = setup_project();
model = load_nonlinear_dynare_model( ...
    fullfile(root,'models','nk_balanced_growth.mod'), ...
    'DeviationScales',struct('gamma_x',0.01));
gain = 0.002;
specification = nk_ee_specification(gain);

% Training volatility applies only to the technology-growth shock. The second
% shock is present in the model interface but exactly dormant in this baseline.
training_standard_deviation = exp(-0.034);
shock_covariance = diag([training_standard_deviation^2,0]);
learning_model = build_ee_learning_model( ...
    model,specification,shock_covariance);

assert(isequal(specification.learned_outcomes, ...
    {'rk','consumption','capital','inflation','output'}));
assert(isequal(size(learning_model.initial_beliefs.coefficients),[5 2]));
assert(strcmp(learning_model.name, ...
    'nk_balanced_growth nk_one_step EE'));

% At the RE beliefs, subjective one-step forecasts must reproduce Dynare's
% transition and shock matrices. This directly tests the PLM-to-ALM algebra,
% rather than merely checking that the resulting path is finite.
[re_transition,re_shock] = extract_re_law(model);
re_alm = learning_model.plm_to_alm(learning_model.re_plm);
assert(max(abs(re_alm.transition-re_transition),[],'all')<1e-10);
assert(max(abs(re_alm.shock_impact-re_shock),[],'all')<1e-10);

% A fixed short sequence proves that the two-shock NK model passes through the
% model-independent simulator while eps_s remains zero in every period.
technology_innovations = [0.10 -0.15 0.05 0.02 -0.08 0.04 0 0.03];
shocks = [technology_innovations;zeros(size(technology_innovations))];
policy = struct('magnitude_limit',1000,'reject_nonfinite',true, ...
    'variable_indices',1:numel(model.variable_names));
run = simulate_learning(learning_model,shocks, ...
    zeros(numel(model.variable_names),1), ...
    learning_model.initial_beliefs,policy);
assert(run.status=="completed");
assert(run.learning_state.observations==numel(technology_innovations));
assert(all(isfinite(run.learning_state.coefficients),'all'));

% Zero gain freezes the exact RE initialization. Because the baseline and
% shocked simulations share all other innovations, their difference must then
% equal the fixed-belief RE impulse response to numerical precision.
zero_gain_model = build_ee_learning_model(model,nk_ee_specification(0), ...
    shock_covariance);
future_shocks = [0.03 -0.02 0.01 0 0;zeros(1,5)];
impulse = [1;0];
paired = simulate_paired_irf(zero_gain_model,shocks,future_shocks,impulse, ...
    zeros(numel(model.variable_names),1), ...
    zero_gain_model.initial_beliefs,policy);
re_irf = make_re_irf(zero_gain_model,size(future_shocks,2),impulse);
assert(paired.status=="completed");
assert(max(abs(paired.native_irf-re_irf),[],'all')<1e-10, ...
    'EPResearch:NkZeroGainMismatch', ...
    'Zero-gain NK EE does not reproduce its Dynare RE impulse response.');

fprintf('NK one-step EE specification passed its short learning check.\n');
end
