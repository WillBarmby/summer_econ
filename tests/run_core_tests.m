function results = run_core_tests()
%% RUN_CORE_TESTS Run the active contract-test suite.
% The suite is deliberately limited to tests/unit. Transitional tests that
% still exercise the old research code can be run directly while the new
% interfaces are built.

root = fileparts(mfilename('fullpath'));
unit_root = fullfile(root,'unit');
suite = matlab.unittest.TestSuite.fromFolder(unit_root, ...
    'IncludingSubfolders',true);
runner = matlab.unittest.TestRunner.withTextOutput;
results = runner.run(suite);

if any([results.Failed])
    error('AdaptiveLearning:CoreTestsFailed', ...
        'One or more active contract tests failed.');
end
end
