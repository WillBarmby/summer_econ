function validate_canonical_model(model)
%% VALIDATE_CANONICAL_MODEL Validate the structural-model interface.

required = {'name','variable_names','shock_names','equation_names', ...
    'current','lag','lead','shock','calibration','re'};
for j = 1:numel(required)
    assert(isfield(model, required{j}), 'Structural model lacks field "%s".', required{j});
end
n = numel(model.variable_names);
q = numel(model.shock_names);
assert(numel(unique(model.variable_names)) == n, 'Variable names must be unique.');
assert(isequal(size(model.current), [n n]), 'Current matrix must be n-by-n.');
assert(isequal(size(model.lag), [n n]), 'Lag matrix must be n-by-n.');
assert(isequal(size(model.lead), [n n]), 'Lead matrix must be n-by-n.');
assert(isequal(size(model.shock), [n q]), 'Shock matrix has wrong dimensions.');
assert(numel(model.equation_names) == n, 'A square linear structural system is required.');
end
