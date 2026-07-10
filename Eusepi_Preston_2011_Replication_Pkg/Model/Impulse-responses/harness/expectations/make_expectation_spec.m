function spec = make_expectation_spec(name, target, horizon, discount)
%% MAKE_EXPECTATION_SPEC Define a VAR-based subjective forecast object.

assert(ischar(name) || isstring(name), 'Expectation name must be text.');
assert(isvector(target) && isnumeric(target), 'Target must be a numeric row vector.');
assert(discount > 0 && discount <= 1, 'Discount must be in (0,1].');
assert(isnumeric(horizon) && any(numel(horizon) == [1 2]), ...
    'Horizon must be a scalar or two-element range.');
if numel(horizon) == 1
    assert(isfinite(horizon) && horizon >= 0 && horizon == floor(horizon));
else
    assert(horizon(1) >= 0 && horizon(1) == floor(horizon(1)));
    assert(horizon(2) > horizon(1) && ...
        (isinf(horizon(2)) || horizon(2) == floor(horizon(2))));
end
spec = struct('name',char(name),'target',target(:).', ...
    'horizon',horizon(:).','discount',discount,'time_shift',0);
end
