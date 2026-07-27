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

fprintf('NK one-step EE specification passed its short learning check.\n');
end
