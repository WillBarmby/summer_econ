function run_harness_tests(include_full_fixture)
%% RUN_HARNESS_TESTS Run layered harness acceptance tests.

if nargin<1, include_full_fixture=false; end
verify_fixture_manifest();
test_expectation_evaluator();
test_ep_ee_alm();
test_ep_ih_alm();
test_ep_learning_path();
test_dynare_expectation_reference();
root=fileparts(fileparts(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))));
verify_ep10_structural_re(root);
verify_ep13_ih_re();
test_nk_plugin();
verify_ir_baseline('baseline_ir_smoke_artifacts.mat');
if include_full_fixture
    verify_ir_baseline('baseline_ir_artifacts.mat');
end
fprintf('All linear macro harness tests passed.\n');
end
