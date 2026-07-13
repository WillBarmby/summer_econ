function verify_ir_workflow(include_full_fixture,tolerance)
%% VERIFY_IR_WORKFLOW Run characterization, structural, and legacy parity checks.

if nargin ~= 2
    error('IRVerification:RequiredArguments', ...
        'include_full_fixture and tolerance are both required.');
end
setup_ir_paths();
run_harness_tests(include_full_fixture);
config = make_ir_config();
config.main.n_draws = 5;
config.main.store_output = false;
comparison = compare_ir_implementations(config,tolerance);
assert(comparison.equivalent,'IRVerification:LegacyMismatch', ...
    'The explicit and legacy-compatible IR paths differ.');
fprintf('Complete IR workflow verification passed.\n');
end
