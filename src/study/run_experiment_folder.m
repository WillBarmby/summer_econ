function artifact = run_experiment_folder(folder_path)
%% RUN_EXPERIMENT_FOLDER Run a self-contained local experiment manifest.
% A single-case folder returns exactly manifest.case_definition and
% manifest.study_options. A comparison folder returns exactly
% manifest.case_definitions and manifest.study_options, where the case
% definitions are a nonempty cell array.
%
% The folder is added temporarily to the MATLAB path while the manifest is
% evaluated. The temporary experiment path, caller path, and caller working
% directory are restored before this function returns, including on errors.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
caller_directory = pwd;
caller_path = path;
cleanup_directory = onCleanup(@() cd(caller_directory)); %#ok<NASGU>
cleanup_caller_path = onCleanup(@() path(caller_path)); %#ok<NASGU>
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
cleanup_folder_path = onCleanup(@() restore_path(folder_path,was_on_path)); %#ok<NASGU>

% Ensure a same-named manifest from another experiment folder is not reused.
clear experiment;
manifest = experiment();
kind = validate_manifest(manifest);

% Keep ROOT explicit in this function: it documents that local manifests are
% configuration above the shared engine, not alternate MATLAB projects.
assert(isfolder(root),'AdaptiveLearning:InvalidExperimentManifest', ...
    'The repository root could not be resolved.');
design = learning_irf_design(manifest.study_options);
if kind=="single"
    prepared = prepare_case(manifest.case_definition);
    artifact = run_case(prepared,design);
else
    prepared = cell(size(manifest.case_definitions));
    for j = 1:numel(manifest.case_definitions)
        prepared{j} = prepare_case(manifest.case_definitions{j});
    end
    artifact = run_comparison(prepared,design);
end
end

function kind = validate_manifest(manifest)
kind = "";
if ~isstruct(manifest) || ~isscalar(manifest) || ...
        ~isfield(manifest,'study_options') || ...
        ~isstruct(manifest.study_options) || ~isscalar(manifest.study_options)
    error('AdaptiveLearning:InvalidExperimentManifest', ...
        ['experiment.m must return either case_definition and study_options, ' ...
        'or case_definitions and study_options.']);
end
fields = sort(fieldnames(manifest));
if isequal(fields,{'case_definition';'study_options'}) && ...
        isstruct(manifest.case_definition) && isscalar(manifest.case_definition)
    kind = "single";
elseif isequal(fields,{'case_definitions';'study_options'}) && ...
        iscell(manifest.case_definitions) && ~isempty(manifest.case_definitions) && ...
        all(cellfun(@(value) isstruct(value)&&isscalar(value), ...
            manifest.case_definitions))
    kind = "comparison";
else
    error('AdaptiveLearning:InvalidExperimentManifest', ...
        ['experiment.m must return a valid single-case or comparison ' ...
        'manifest with exact field names.']);
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
