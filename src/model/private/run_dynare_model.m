function output = run_dynare_model(source,parameter_overrides,extractor)
%% RUN_DYNARE_MODEL Own one complete Dynare runtime lifecycle.
% Dynare communicates through global data stores and generated functions.
% This helper confines both to a temporary directory, gives a private
% extraction callback temporary access to them, and cleans up before any
% public model value is returned.

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
evalin('base',make_dynare_command(source.name,parameter_overrides));

global M_ oo_ %#ok<GVMIS>
if ~isstruct(M_) || ~isfield(M_,'fname') || ~strcmp(M_.fname,source.name)
    error('AdaptiveLearning:DynareState', ...
        'Dynare did not return state for the requested model.');
end

context = struct( ...
    'M',M_, ...
    'oo',oo_, ...
    'residual_function',str2func([source.name '.dynamic_resid']));
output = extractor(context);

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
