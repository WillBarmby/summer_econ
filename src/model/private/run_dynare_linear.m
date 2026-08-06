function components = run_dynare_linear(source,options)
%% RUN_DYNARE_LINEAR Run Dynare and keep its data store private.
% Dynare publishes M_ and oo_ in the base workspace and generates a driver
% plus dynamic functions. This helper owns that lifecycle: it copies the
% source into a temporary directory, runs Dynare there, extracts components
% while the generated residual function is available, and removes the entire
% runtime workspace before returning to LOAD_MODEL.

configure_runtime();
reset_runtime();
cleanup_state = onCleanup(@reset_runtime);

work = tempname;
mkdir(work);
cleanup_work = onCleanup(@() remove_work_directory(work));
copyfile(source.file,fullfile(work,[source.name '.mod']));

old_directory = pwd;
cleanup_directory = onCleanup(@() cd(old_directory));
cd(work);
evalin('base',make_dynare_command(source.name,options.parameter_overrides));

global M_ oo_ %#ok<GVMIS>
if ~isstruct(M_) || ~strcmp(M_.fname,source.name)
    error('AdaptiveLearning:DynareState', ...
        'Dynare did not return state for the requested model.');
end

residual_function = str2func([source.name '.dynamic_resid']);
components = extract_linear_components(M_,oo_,residual_function);

% Explicit clearing makes the cleanup order readable on the success path;
% onCleanup handles the same guarantees if extraction or Dynare fails.
clear cleanup_directory;
clear cleanup_work;
clear cleanup_state;
end

function configure_runtime()
matlab_path = getenv('DYNARE_MATLAB_PATH');
if isempty(matlab_path) && isfolder('/Applications/Dynare/7.1-arm64/matlab')
    matlab_path = '/Applications/Dynare/7.1-arm64/matlab';
end
if isempty(matlab_path) || ~isfolder(matlab_path)
    error('AdaptiveLearning:DynareNotFound', ...
        'Dynare 7.1 was not found or DYNARE_MATLAB_PATH is invalid.');
end
addpath(matlab_path);
version = dynare_version();
if ~startsWith(version,'7.1')
    error('AdaptiveLearning:DynareVersion', ...
        'Expected Dynare 7.1, detected %s.',version);
end
end

function reset_runtime()
evalin('base','clear global M_ oo_; clear M_ oo_;');
clear global M_ oo_
end

function command = make_dynare_command(name,overrides)
options = {'noclearall','nolog'};
names = fieldnames(overrides);
for j = 1:numel(names)
    options{end+1} = sprintf('-D%s=%.17g', ...
        names{j},overrides.(names{j})); %#ok<AGROW>
end
command = sprintf('dynare %s %s',name,strjoin(options,' '));
end

function remove_work_directory(work)
if isfolder(work)
    rmdir(work,'s');
end
end
