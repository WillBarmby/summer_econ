function re_solution = extract_re_solution(context,structural_model)
%% EXTRACT_RE_SOLUTION Translate Dynare's decision rule into public order.
% Dynare stores rows and state columns in solver-specific order. This is the
% only place that knows that layout; the returned matrices use the variable
% and shock declaration order promised by the public contract.

M = context.M;
oo = context.oo;
if ~isfield(oo,'dr') || ~isstruct(oo.dr) || ...
        ~all(isfield(oo.dr,{'ghx','ghu','order_var','state_var'}))
    error('AdaptiveLearning:RESolutionFailure', ...
        'Dynare did not return a first-order decision rule.');
end

assert_declaration_order(M,structural_model);
rule = oo.dr;
n = numel(structural_model.variable_names);
q = numel(structural_model.shock_names);
scales = structural_model.transformation.deviation_scales(:);
if ~isequal(size(scales),[n 1]) || any(~isfinite(scales) | scales<=0)
    error('AdaptiveLearning:InvalidStructuralModel', ...
        'The structural model has invalid deviation scales.');
end
row_scales = scales(rule.order_var);
state_scales = scales(rule.state_var);
ghx = diag(1./row_scales)*rule.ghx*diag(state_scales);
ghu = diag(1./row_scales)*rule.ghu;

transition = zeros(n,n);
transition(rule.order_var,rule.state_var) = ghx;
shock = zeros(n,q);
shock(rule.order_var,:) = ghu;

re_solution = struct( ...
    'intercept',zeros(n,1), ...
    'transition',transition, ...
    'shock',shock, ...
    'state_indices',rule.state_var(:).', ...
    'variable_names',{structural_model.variable_names}, ...
    'shock_names',{structural_model.shock_names});
end

function assert_declaration_order(M,structural_model)
variables = cellstr(string(M.endo_names(:).'));
shocks = cellstr(string(M.exo_names(:).'));
if ~isequal(variables,structural_model.variable_names) || ...
        ~isequal(shocks,structural_model.shock_names)
    error('AdaptiveLearning:ModelSourceMismatch', ...
        'The Dynare source declarations differ from the structural model.');
end
end
