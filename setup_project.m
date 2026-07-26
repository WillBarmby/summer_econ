function root = setup_project()
%% SETUP_PROJECT Add only the clean research interface to the MATLAB path.
% Returns the repository root so runners can construct stable model and
% results paths without depending on the caller's working directory.

root = fileparts(mfilename('fullpath'));
folders = {'config',fullfile('src','model'), ...
    fullfile('src','learning'),fullfile('src','expectations'), ...
    fullfile('src','reporting'),'tests'};
for j = 1:numel(folders)
    path = fullfile(root,folders{j});
    if isfolder(path)
        addpath(path,'-end');
    end
end
end
