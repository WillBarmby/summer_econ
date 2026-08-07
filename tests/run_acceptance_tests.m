function results = run_acceptance_tests()
%% RUN_ACCEPTANCE_TESTS Run slower frozen-fixture parity checks.

root = fileparts(mfilename('fullpath'));
suite = matlab.unittest.TestSuite.fromFolder( ...
    fullfile(root,'acceptance'),'IncludingSubfolders',true);
results = run(suite);
if any([results.Failed])
    error('AdaptiveLearning:AcceptanceTestsFailed', ...
        'One or more legacy parity tests failed.');
end
end
