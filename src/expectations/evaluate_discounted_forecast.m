function forecast = evaluate_discounted_forecast(plm,target,horizon,discount)
%% EVALUATE_DISCOUNTED_FORECAST Evaluate a discounted PLM forecast or sum.
% horizon is either a nonnegative integer or [first,last], where last may be
% Inf. The PLM is y_t=intercept+transition*y_(t-1).
%
% Write the affine PLM with an augmented state:
%                 [1       0] [1        ]
%   [1; y_(t+j)] = [a       B] [1; y_t  ] = P*[1; y_t].
% More generally, conditional means j periods ahead are P^j*[1; y_t].
% The row [0,target] selects the desired linear combination of y. Thus
%
%   discount^j E_t[target*y_(t+j)]
%       = [0,target]*(discount*P)^j*[1; y_t].
%
% The returned intercept and coefficients are the first and remaining
% elements of that row. For an infinite range, the geometric-series identity
%   sum_{j=0}^Inf (discount*P)^j = (I-discount*P)^(-1)
% supplies the closed form. The leading unit state is deliberately excluded
% from the stability check: it represents the affine constant, while
% convergence of the variable coefficients requires spectral radius
% discount*B < 1.

mu = plm.intercept(:);
transition = plm.transition;
n = numel(mu);
assert(isequal(size(transition),[n n]) && numel(target)==n, ...
    'EPResearch:InvalidForecast','Forecast target and PLM dimensions differ.');
assert(discount>0 && discount<=1,'EPResearch:InvalidForecast', ...
    'Discount must lie in (0,1].');
companion = [1 zeros(1,n);mu transition];
selector = [0 target(:).'];
discounted = discount*companion;
if isscalar(horizon)
    assert(horizon>=0 && horizon==fix(horizon), ...
        'EPResearch:InvalidForecast','Forecast horizon must be an integer.');
    row = selector*(discounted^horizon);
elseif numel(horizon)==2 && isinf(horizon(2))
    assert(horizon(1)>=0 && horizon(1)==fix(horizon(1)), ...
        'EPResearch:InvalidForecast','Forecast range must start at an integer.');
    assert(max(abs(eig(discounted(2:end,2:end))))<1, ...
        'EPResearch:UnstableForecast','Infinite discounted sum does not exist.');
    row = selector/(eye(n+1)-discounted);
    % Remove terms dated before the requested first horizon from the full
    % j=0,...,Inf geometric sum.
    for j = 0:horizon(1)-1
        row = row-selector*(discounted^j);
    end
else
    assert(numel(horizon)==2 && all(isfinite(horizon)) && ...
        horizon(1)>=0 && horizon(2)>horizon(1) && ...
        all(horizon==fix(horizon)),'EPResearch:InvalidForecast', ...
        'Finite forecast range is invalid.');
    row = zeros(1,n+1);
    for j = horizon(1):horizon(2)
        row = row+selector*(discounted^j);
    end
end
forecast = struct('intercept',row(1),'coefficients',row(2:end), ...
    'stability_root',max(abs(eig(discounted(2:end,2:end)))));
end
