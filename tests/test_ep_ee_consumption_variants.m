function test_ep_ee_consumption_variants()
%% TEST_EP_EE_CONSUMPTION_VARIANTS Verify the two forecast contracts directly.

root = setup_project();
config = ep_experiment_config();
model = load_linear_dynare_model(fullfile(root,'models','ep_rbc_ee.mod'), ...
    'ParameterOverrides',ep_calibration(config.gamma_bar).parameter_overrides);
variance = config.training_shock_standard_deviation^2;
direct = build_ee_learning_model(model,ep_ee_specification(config.gain, ...
    "paper_direct_consumption"),variance);
archive = build_ee_learning_model(model,ep_ee_specification(config.gain, ...
    "archive_fixed_re_consumption"),variance);
c = find(strcmp(model.variable_names,'consumption'),1);

% Both treatments begin at the identical RE PLM and therefore imply the same
% pre-update ALM, despite estimating different sets of outcomes afterward.
direct_initial = direct.beliefs_to_plm(direct.initial_beliefs);
archive_initial = archive.beliefs_to_plm(archive.initial_beliefs);
assert(isequal(direct_initial,archive_initial));
assert_alm_equal(direct.plm_to_alm(direct_initial), ...
    archive.plm_to_alm(archive_initial));

% Changing only the directly learned consumption row changes actual decisions.
changed = direct.initial_beliefs;
direct_c = find(strcmp(direct.specification.learned_outcomes,'consumption'),1);
changed.coefficients(direct_c,1) = changed.coefficients(direct_c,1)+0.1;
changed_alm = direct.plm_to_alm(direct.beliefs_to_plm(changed));
assert(norm(changed_alm.intercept- ...
    direct.plm_to_alm(direct_initial).intercept)>1e-8);

% One common innovation produces the same first observation, then updates the
% direct consumption row while the archive row remains exactly fixed at RE.
policy = struct('magnitude_limit',config.explosion_magnitude, ...
    'reject_nonfinite',true,'variable_indices',1:numel(model.variable_names));
direct_run = simulate_learning(direct,0.25,zeros(numel(model.variable_names),1), ...
    direct.initial_beliefs,policy);
archive_run = simulate_learning(archive,0.25,zeros(numel(model.variable_names),1), ...
    archive.initial_beliefs,policy);
assert(isequal(direct_run.native_path(:,2),archive_run.native_path(:,2)));
direct_after = direct.beliefs_to_plm(direct_run.learning_state);
archive_after = archive.beliefs_to_plm(archive_run.learning_state);
assert(norm(direct_after.intercept(c)-direct_initial.intercept(c))+ ...
    norm(direct_after.transition(c,:)-direct_initial.transition(c,:))>0);
assert(isequal(archive_after.intercept(c),archive.re_plm.intercept(c)));
assert(isequal(archive_after.transition(c,:),archive.re_plm.transition(c,:)));
assert(direct_run.learning_state.observations==1 && ...
    archive_run.learning_state.observations==1);
fprintf('E&P EE consumption-forecast contracts passed focused tests.\n');
end

function assert_alm_equal(first,second)
for field = {'intercept','transition','shock_impact'}
    assert(max(abs(first.(field{1})-second.(field{1})),[],'all')<1e-12);
end
end
