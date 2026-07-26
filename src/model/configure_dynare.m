function info = configure_dynare()
%% CONFIGURE_DYNARE Locate and validate the supported Dynare 7.1 runtime.
% Set DYNARE_MATLAB_PATH to override the standard macOS installation path.

matlab_path = getenv('DYNARE_MATLAB_PATH');
if isempty(matlab_path) && isfolder('/Applications/Dynare/7.1-arm64/matlab')
    matlab_path = '/Applications/Dynare/7.1-arm64/matlab';
end
assert(~isempty(matlab_path) && isfolder(matlab_path), ...
    'EPResearch:DynareNotFound', ...
    ['Dynare 7.1 was not found. Set DYNARE_MATLAB_PATH to its MATLAB ' ...
     'directory.']);
addpath(matlab_path);
version = dynare_version();
assert(startsWith(version,'7.1'),'EPResearch:DynareVersion', ...
    'The research loader supports Dynare 7.1; detected %s.',version);
info = struct('matlab_path',matlab_path,'version',version);
end
