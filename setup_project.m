function root = setup_project()
%% SETUP_PROJECT Add only the clean research interface to the MATLAB path.
% Returns the repository root so callers can construct stable model paths
% without depending on the caller's working directory.

root = fileparts(mfilename('fullpath'));
folders = {'models', ...
    fullfile('src','model'), ...
    fullfile('src','learning'), ...
    fullfile('src','expectations'), ...
    'tests'};
for j = 1:numel(folders)
    folder_path = fullfile(root,folders{j});
    if isfolder(folder_path)
        addpath(folder_path,'-end');
    end
end
end
