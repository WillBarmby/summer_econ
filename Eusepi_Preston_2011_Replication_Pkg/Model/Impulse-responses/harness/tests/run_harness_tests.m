function run_harness_tests(include_full_fixture)
%% RUN_HARNESS_TESTS Run layered harness acceptance tests.

if nargin~=1
    error('Harness:RequiredOptions','include_full_fixture must be supplied explicitly.');
end
verify_fixture_manifest();
test_dynare_71_jacobian_unpacking();
test_nk_first_order_model();
test_nk_ee_learning_contract();
test_nk_ee_irfs();
test_learning_comparison_panels();
test_expectation_evaluator();
test_ep_ee_alm();
test_ep_ih_alm();
test_dynare_ih_learning_adapter();
test_dynare_quantities_irfs();
test_ep_learning_path();
test_ep_ee_learning_path();
test_ep_ee_dynare_learning_path();
test_ep_ee_paper_specification();
test_update_rls();
test_ep_archive_moments();
test_dynare_expectation_reference();
verify_ep10_structural_re();
verify_ep13_ih_re();
verify_ir_baseline('baseline_ir_smoke_artifacts.mat',1e-10);
if include_full_fixture
    verify_ir_baseline('baseline_ir_artifacts.mat',1e-10);
end
fprintf('All linear macro harness tests passed.\n');
end
