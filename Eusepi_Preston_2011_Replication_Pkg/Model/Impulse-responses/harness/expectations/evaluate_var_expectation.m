function result = evaluate_var_expectation(plm, spec)
%% EVALUATE_VAR_EXPECTATION Direct evaluator matching Dynare 7.1 formulas.
%
% PLM is y_t = intercept + transition*y_{t-1}. The augmented state is
% [1;y_t], allowing nonzero perceived-law intercepts.

mu = plm.intercept(:);
C = plm.transition;
n = numel(mu);
assert(isequal(size(C), [n n]), 'PLM transition must be n-by-n.');
assert(numel(spec.target) == n, 'Expectation target does not match PLM dimension.');
companion = [1 zeros(1,n); mu C];
alpha = [0 spec.target(:).'];
dC = spec.discount*companion;
h = spec.horizon;
if numel(h) == 1
    row = alpha*(dC^h);
elseif isinf(h(2))
    assert(max(abs(eig(dC(2:end,2:end)))) < 1, ...
        'Discounted PLM is unstable; infinite forecast sum does not exist.');
    row = alpha/(eye(n+1)-dC);
    if h(1) > 0
        for j = 0:h(1)-1
            row = row-alpha*(dC^j);
        end
    end
else
    row = zeros(1,n+1);
    for j = h(1):h(2)
        row = row+alpha*(dC^j);
    end
end
result = struct('name',spec.name,'intercept',row(1), ...
    'coefficients',row(2:end),'augmented_coefficients',row, ...
    'companion',companion,'stability_root',max(abs(eig(dC(2:end,2:end)))));
end
