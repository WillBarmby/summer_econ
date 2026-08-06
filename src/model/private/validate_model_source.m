function source = validate_model_source(model_file,options)
%% VALIDATE_MODEL_SOURCE Validate the file before invoking Dynare.
% The source metadata is retained as a non-Dynare handle for the later
% SOLVE_RE boundary. No generated runtime object crosses this boundary.

if ~(ischar(model_file) || (isstring(model_file) && isscalar(model_file)))
    error('AdaptiveLearning:InvalidModelFile', ...
        'The model file must be a text scalar path.');
end
model_file = char(model_file);
if ~isfile(model_file)
    error('AdaptiveLearning:MissingModelFile', ...
        'Dynare model not found: %s',model_file);
end

[~,name,extension] = fileparts(model_file);
if ~isvarname(name) || ~strcmpi(extension,'.mod')
    error('AdaptiveLearning:InvalidModelFile', ...
        'The model file must have a valid MATLAB identifier as its name.');
end

text = fileread(model_file);
if options.kind=="linear" && isempty(regexp(text, ...
        'model\s*\([^;)]*linear[^;)]*\)\s*;','once'))
    error('AdaptiveLearning:NonlinearModel', ...
        'This first loader accepts only an explicit model(linear) file.');
end

source = struct('file',model_file,'name',name,'kind',options.kind);
end
