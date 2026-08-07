function verify_parameter_overrides(calibration,overrides)
%% VERIFY_PARAMETER_OVERRIDES Ensure requested Dynare macros changed parameters.

names = fieldnames(overrides);
for j = 1:numel(names)
    name = names{j};
    if ~isfield(calibration,name)
        error('AdaptiveLearning:UnknownParameter', ...
            'Model does not declare parameter "%s".',name);
    end
    requested = overrides.(name);
    tolerance = 1e-12*max(1,abs(requested));
    if abs(calibration.(name)-requested)>tolerance
        error('AdaptiveLearning:UnusedParameterOverride', ...
            'Parameter override "%s" was not applied.',name);
    end
end
end
