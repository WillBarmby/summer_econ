function [transition,shock] = extract_re_law(model)
%% EXTRACT_RE_LAW Express Dynare's ordered decision rule in model-name order.
% Dynare stores its first-order solution in decision-rule order:
%   y_t(order_var) = ghx*y_(t-1)(state_var) + ghu*eps_t.
% The learning code instead uses full matrices in declaration order,
%   y_t = transition*y_(t-1) + shock*eps_t.
% The indexed assignments below embed Dynare's compact matrices in that
% common n-variable representation; non-state columns remain zero.

validate_structural_model(model);
rule = model.re.decision_rule;
n = numel(model.variable_names);
transition = zeros(n);
transition(rule.order_var,rule.state_var) = rule.ghx;
shock = zeros(n,size(rule.ghu,2));
shock(rule.order_var,:) = rule.ghu;
end
