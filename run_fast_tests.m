function run_fast_tests()
%% RUN_FAST_TESTS Run the clean interface's short development checks.

setup_project();
error('EPResearch:EngineNotInstalled', ...
    'Fast tests become active after the minimal engine is installed.');
end
