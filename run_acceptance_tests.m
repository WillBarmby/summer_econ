function run_acceptance_tests()
%% RUN_ACCEPTANCE_TESTS Run the clean interface's numerical acceptance checks.

setup_project();
error('EPResearch:EngineNotInstalled', ...
    'Acceptance tests become active after the clean E&P interface is installed.');
end
