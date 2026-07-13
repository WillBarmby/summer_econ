function alm = dynare_ih_plm_to_alm(model,plm,config)
%% DYNARE_IH_PLM_TO_ALM Apply E&P subjective IH forecasts to Dynare equations.

n = numel(model.variable_names);
assert(isequal(size(plm.transition),[n n]),'EPIH:InvalidPLM', ...
    'PLM transition must match the Dynare model dimension.');

lhs = model.current + model.lead*plm.transition;
constant = model.lead*plm.intercept(:);
lag = model.lag;
shock = model.shock;
beta = model.calibration.beta_tilda;

for j=1:numel(config.forecast_targets)
    target_name = config.forecast_targets{j};
    sum_name = config.present_value_variables{j};
    equation_name = config.present_value_equations{j};
    target_index = find(strcmp(model.variable_names,target_name));
    sum_index = find(strcmp(model.variable_names,sum_name));
    equation_index = find(strcmp(model.equation_names,equation_name));
    % The Dynare auxiliary stores beta times E&P's sum whose first weight
    % is one. A unit target with discount beta therefore has weights
    % beta^h, h>=1, exactly matching that internal normalization.
    target = zeros(1,n); target(target_index)=1;
    forecast = evaluate_var_expectation(plm, ...
        make_expectation_spec(['discounted_' target_name],target,[1 Inf],beta));
    lhs(equation_index,:) = -forecast.coefficients;
    lhs(equation_index,sum_index) = lhs(equation_index,sum_index)+1;
    constant(equation_index) = -forecast.intercept;
    lag(equation_index,:) = 0;
    shock(equation_index,:) = 0;
end

% Dynare's recursive auxiliaries reproduce the RE solution, but the learning
% model must evaluate the complete E&P consumption rule under the supplied
% subjective PLM. In particular, expected technology growth cannot be
% omitted merely because its RE forecast is zero in the i.i.d. calibration.
decision_index = find(strcmp(model.equation_names,config.decision_equation));
sum_indices = cellfun(@(name) find(strcmp(model.variable_names,name)), ...
    config.present_value_variables);
lhs(decision_index,sum_indices) = 0;
p = model.calibration;
forecast_coefficients = [p.beta_tilda-p.c_c, ...
    -p.beta_tilda*p.R_tilda*(p.beta_tilda/p.sigma-p.c_c), ...
    p.c_c*p.beta_tilda*(p.eps_w+p.eps_c*p.chi/(1-p.chi))];
for j=1:numel(config.decision_forecast_targets)
    target_index = find(strcmp(model.variable_names,config.decision_forecast_targets{j}));
    target = zeros(1,n); target(target_index)=1/beta;
    forecast = evaluate_var_expectation(plm, ...
        make_expectation_spec('decision_forecast',target,[1 Inf],beta));
    lhs(decision_index,:) = lhs(decision_index,:)-forecast_coefficients(j)*forecast.coefficients;
    constant(decision_index) = constant(decision_index)-forecast_coefficients(j)*forecast.intercept;
end

assert(rcond(lhs)>config.rcond_tolerance,'EPIH:SingularALM', ...
    'Belief-dependent IH system is singular or ill-conditioned.');
alm = struct('intercept',-(lhs\constant),'transition',-(lhs\lag), ...
    'shock_impact',-(lhs\shock),'stability_root',NaN);
alm.stability_root = max(abs(eig(alm.transition)));
end
