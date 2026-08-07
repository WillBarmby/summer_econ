function shocks = materialize_named_shocks( ...
    shock_names,shock_name,innovations,scale)
%% MATERIALIZE_NAMED_SHOCKS Resolve economic names into model shock order.

if ~(isnumeric(innovations) && isreal(innovations) && isrow(innovations) && ...
        all(isfinite(innovations))) || ...
        ~(isnumeric(scale) && isscalar(scale) && isfinite(scale))
    error('AdaptiveLearning:InvalidStudyDesign', ...
        'Innovations and scale must be finite real values.');
end
[found,index] = ismember(string(shock_name),string(shock_names));
if ~found
    error('AdaptiveLearning:UnknownShock', ...
        'Model does not declare shock "%s".',string(shock_name));
end
shocks = zeros(numel(shock_names),numel(innovations));
shocks(index,:) = scale*innovations;
end
