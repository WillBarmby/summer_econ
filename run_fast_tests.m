function run_fast_tests()
%% RUN_FAST_TESTS Run the clean interface's short development checks.
% Covers model loading, matrix extraction, RLS arithmetic, fixed short EE/IH
% paths, paired shock timing, failure statuses, and a saved graph smoke test.

setup_project();
test_minimal_engine();
test_nonlinear_loader();
test_nk_ee_specification();
test_nk_risk_premium_smoke();
test_ep_smoke();
fprintf('All fast tests passed.\n');
end
