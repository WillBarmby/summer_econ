function root = setup_project()
%% SETUP_PROJECT Add only the clean research interface to the MATLAB path.
% Returns the repository root so runners can construct stable model and
% results paths without depending on the caller's working directory.

root = fileparts(mfilename('fullpath'));
% A researcher may call the clean runner after using the archived replication
% workflow in the same MATLAB session. Remove only paths inside that frozen
% tree so name resolution cannot silently select a legacy implementation.
legacy_root = fullfile(root,'Eusepi_Preston_2011_Replication_Pkg');
entries = strsplit(path,pathsep);
legacy_entries = entries(startsWith(entries,[legacy_root filesep]) | ...
    strcmp(entries,legacy_root));
if ~isempty(legacy_entries)
    rmpath(legacy_entries{:});
end

folders = {'config','models',fullfile('src','model'), ...
    fullfile('src','learning'),fullfile('src','expectations'), ...
    fullfile('src','reporting'),'tests'};
for j = 1:numel(folders)
    folder_path = fullfile(root,folders{j});
    if isfolder(folder_path)
        addpath(folder_path,'-end');
    end
end
end
