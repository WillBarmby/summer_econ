function calibration = parameter_struct(M)
%% PARAMETER_STRUCT Preserve Dynare's effective scalar calibration.

calibration = struct();
for j = 1:numel(M.param_names)
    calibration.(M.param_names{j}) = M.params(j);
end
end
