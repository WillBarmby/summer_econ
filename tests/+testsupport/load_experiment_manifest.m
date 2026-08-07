function manifest = load_experiment_manifest(folder,varargin)
%% LOAD_EXPERIMENT_MANIFEST Load a local manifest for tests only.

folder = char(string(folder));
entries = strsplit(path,pathsep);
was_on_path = any(strcmp(entries,folder));
if ~was_on_path
    addpath(folder,'-begin');
end
cleanup = onCleanup(@() restore_manifest_path(folder,was_on_path)); %#ok<NASGU>
clear experiment;
if isempty(varargin)
    manifest = experiment();
else
    manifest = experiment(varargin{1});
end
end

function restore_manifest_path(folder,was_on_path)
if ~was_on_path
    entries = strsplit(path,pathsep);
    if any(strcmp(entries,folder))
        rmpath(folder);
    end
end
clear experiment;
end
