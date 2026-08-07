function artifact = run_experiment_folder(folder_path)
%% RUN_EXPERIMENT_FOLDER Run a self-contained local experiment manifest.
% The folder must contain an experiment.m function returning exactly:
%   manifest.case_definition
%   manifest.study_options
%
% The folder is added temporarily to the MATLAB path while the manifest is
% evaluated. The engine path and caller working directory are restored before
% this function returns, including on errors.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
setup_project();

folder_path = char(string(folder_path));
if ~isfolder(folder_path)
    error('AdaptiveLearning:InvalidExperimentManifest', ...
        'Experiment folder does not exist: %s.',folder_path);
end
folder_path = char(java.io.File(folder_path).getCanonicalPath());
manifest_file = fullfile(folder_path,'experiment.m');
if ~isfile(manifest_file)
    error('AdaptiveLearning:InvalidExperimentManifest', ...
        'Experiment folder must contain experiment.m: %s.',folder_path);
end

entries = strsplit(path,pathsep);
was_on_path = any(strcmp(entries,folder_path));
if ~was_on_path
    addpath(folder_path,'-begin');
end
cleanup_path = onCleanup(@() restore_path(folder_path,was_on_path)); %#ok<NASGU>

% Ensure a same-named manifest from another experiment folder is not reused.
clear experiment;
manifest = experiment();
validate_manifest(manifest);

% Keep ROOT explicit in this function: it documents that local manifests are
% configuration above the shared engine, not alternate MATLAB projects.
assert(isfolder(root),'AdaptiveLearning:InvalidExperimentManifest', ...
    'The repository root could not be resolved.');
prepared = prepare_case(manifest.case_definition);
design = learning_irf_design(manifest.study_options);
artifact = run_case(prepared,design);
end

function validate_manifest(manifest)
if ~isstruct(manifest) || ~isscalar(manifest) || ...
        ~isequal(sort(fieldnames(manifest)),{'case_definition';'study_options'}) || ...
        ~isstruct(manifest.case_definition) || ~isscalar(manifest.case_definition) || ...
        ~isstruct(manifest.study_options) || ~isscalar(manifest.study_options)
    error('AdaptiveLearning:InvalidExperimentManifest', ...
        'experiment.m must return case_definition and study_options structs.');
end
end

function restore_path(folder_path,was_on_path)
if ~was_on_path
    entries = strsplit(path,pathsep);
    if any(strcmp(entries,folder_path))
        rmpath(folder_path);
    end
end
clear experiment;
end
