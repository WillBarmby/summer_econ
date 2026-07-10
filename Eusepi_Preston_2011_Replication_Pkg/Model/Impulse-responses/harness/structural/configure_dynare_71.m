function info = configure_dynare_71()
%% CONFIGURE_DYNARE_71 Locate and validate the supported Dynare runtime.

path_value = getenv('DYNARE_MATLAB_PATH');
if isempty(path_value)
    local_config = fullfile(fileparts(mfilename('fullpath')),'local_dynare_config.m');
    if isfile(local_config)
        data = run(local_config); %#ok<NASGU>
        if exist('DYNARE_MATLAB_PATH','var')
            path_value = DYNARE_MATLAB_PATH;
        end
    end
end
if isempty(path_value) && isfolder('/Applications/Dynare/7.1-arm64/matlab')
    path_value = '/Applications/Dynare/7.1-arm64/matlab';
end
assert(~isempty(path_value) && isfolder(path_value), ...
    ['Dynare 7.1 was not found. Set DYNARE_MATLAB_PATH to its matlab ' ...
     'directory or provide structural/local_dynare_config.m.']);
addpath(path_value);
version = dynare_version();
assert(startsWith(version,'7.1'), ...
    'This loader guarantees Dynare 7.1 only; detected %s.',version);
info = struct('matlab_path',path_value,'version',version);
end
