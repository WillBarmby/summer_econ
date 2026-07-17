function test_ep_ee_learning_path()
%% Compare the generic and legacy EE simulation loops.
% This is a refactoring-parity test. Both implementations intentionally
% share the archived structural matrices, RE initialization, and ALM
% solver; independent structural validation is handled separately.


% Begin with default parameter values
cfg = ir_default_config();
param = cfg.main.model_param;
param(1) = 0;       % Euler-equation decision rule
param(6) = 0.002;   % archived small-gain EE case
shock_scale = exp(-0.144);

[plugin, initial_state] = make_ep_learning_plugin(...
    param, shock_scale^2);

% The archive estimates seven equations, each with [constant, lagged capital].
assert(isequal(size(initial_state.coefficients), [7 2]));

% Generate one reproducible sequence of innovations.
rng(32);
innovations = randn(1, 300);

% Simulate using the generic learning engine.
generic_shocks = shock_scale * innovations(1:end-1);

generic = simulate_learning_path( ...
    plugin, ...
    generic_shocks, ...
    zeros(13,1), ...
    initial_state, ...
    cfg.main.explosion_policy);

% Simulate the same experiment using the legacy implementation.
[legacy_path,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~, ...
    legacy_invalid,legacy_status] = ...
    simulate_model_paths( ...
        param, ...
        shock_scale, ...
        true, ...   % feedback
        true, ...   % learning
        false, ...  % expectation generation
        false, ...  % impulse-response mode
        true, ...   % full simulation
        1, ...      % unused initial impulse
        0,0,0,0,0, ...
        1, ...      % unused training length outside IR mode
        innovations, ...
        cfg.main.explosion_policy);

% Check that both simulations completed successfully.
assert(generic.status == "completed");
assert(~legacy_invalid);
assert(legacy_status.status == "completed");

% Compare every variable in every period.
max_difference = max(abs(generic.native_path - legacy_path), [], 'all');

assert(max_difference < 1e-10, ...
    'Generic and legacy EE paths differ by %.16g.', max_difference);

fprintf( ...
    'Complete EE learning-path parity passed; max difference %.3g.\n', ...
    max_difference);
end