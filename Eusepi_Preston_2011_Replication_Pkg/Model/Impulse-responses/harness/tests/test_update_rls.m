function test_update_rls()
%% TEST_UPDATE_RLS Verify one RLS update against a hand calculation.

old_B = [1 2; -1 0.5];
old_R = eye(2);
x = [1; 2];
y = [6; 0];
gain = 0.1;

config = struct();
config.initial_coefficients = old_B;
config.initial_moment_matrix = old_R;
config.gain = struct( ...
    'type','constant', ...
    'value',gain, ...
    'offset',0);
config.rcond_tolerance = 1e-12;
config.project = [];

state = initialize_learning_state(config);

[new_state, diagnostic] = update_rls( ...
    state, x, y, config);

expected_R = [1 0.2; 0.2 1.3];
expected_B = [15/14 15/7; -1 1/2];
expected_error = [1; 0];

assert(max(abs(new_state.moment_matrix-expected_R),[],'all') < 1e-12);
assert(max(abs(new_state.coefficients-expected_B),[],'all') < 1e-12);
assert(max(abs(diagnostic.prediction_error-expected_error)) < 1e-12);

assert(new_state.observations == 1);
assert(new_state.projection_events == 0);
assert(~new_state.invalid);
assert(~diagnostic.projected);
assert(abs(diagnostic.gain-gain) < 1e-12);

fprintf('Hand-calculated RLS update test passed.\n');
end