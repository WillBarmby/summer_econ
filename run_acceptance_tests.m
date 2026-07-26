function run_acceptance_tests()
%% RUN_ACCEPTANCE_TESTS Run the clean interface's numerical acceptance checks.
% Runs the public-interface contract and full retained-summary comparisons.
% Compact fixtures are inputs; this suite never executes the archived tree.

setup_project();
test_ep_public_interface();
test_ep_acceptance();
fprintf('All acceptance tests passed.\n');
end
