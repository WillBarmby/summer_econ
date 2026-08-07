function forecast = evaluate_discounted_forecast(plm,target,discount)
%% EVALUATE_DISCOUNTED_FORECAST Sum discounted PLM forecasts from t+1 onward.
% For affine y_t=a+B*y_(t-1), the augmented companion matrix maps
% [1;y_t] into conditional future values. The geometric sum returns
% sum_{h=1}^Inf discount^h E_t[target*y_(t+h)].

intercept = plm.intercept(:);
transition = plm.transition;
n = numel(intercept);
if ~isequal(size(transition),[n n]) || numel(target)~=n || ...
        ~isnumeric(target) || ~isreal(target) || ...
        ~isnumeric(discount) || ~isreal(discount) || ...
        ~isscalar(discount) || ~isfinite(discount) || ...
        discount<=0 || discount>1
    error('AdaptiveLearning:InvalidLearningSystem', ...
        'Discounted forecast inputs are malformed.');
end
discounted_transition = discount*transition;
stability_root = max(abs(eig(discounted_transition)));
if stability_root>=1
    error('AdaptiveLearning:UnstableForecast', ...
        'Infinite discounted forecast sum does not converge.');
end
companion = [1 zeros(1,n);intercept transition];
selector = [0 target(:).'];
discounted = discount*companion;
row = selector/(eye(n+1)-discounted)-selector;
forecast = struct( ...
    'intercept',row(1), ...
    'coefficients',row(2:end), ...
    'stability_root',stability_root);
end
