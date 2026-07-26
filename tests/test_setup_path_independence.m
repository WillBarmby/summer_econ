function test_setup_path_independence()
%% TEST_SETUP_PATH_INDEPENDENCE Ensure setup excludes the frozen tree.

root = fileparts(fileparts(mfilename('fullpath')));
legacy = fullfile(root,'Eusepi_Preston_2011_Replication_Pkg','Model', ...
    'Impulse-responses','harness','learning');
addpath(legacy);
setup_project();
entries = strsplit(path,pathsep);
frozen_root = fullfile(root,'Eusepi_Preston_2011_Replication_Pkg');
assert(~any(startsWith(entries,[frozen_root filesep]) | ...
    strcmp(entries,frozen_root)),'EPResearch:LegacyPathActive', ...
    'setup_project left a frozen-tree directory on the MATLAB path.');
required = {'config','models',fullfile('src','model'), ...
    fullfile('src','learning'),fullfile('src','expectations'), ...
    fullfile('src','reporting'),'tests'};
for j = 1:numel(required)
    assert(any(strcmp(entries,fullfile(root,required{j}))), ...
        'EPResearch:MissingCleanPath','Clean path is missing: %s.',required{j});
end
end
