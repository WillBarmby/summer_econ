function alm = plm_to_alm_ep_ih(model,plm,specification)
%% PLM_TO_ALM_EP_IH Apply E&P infinite-horizon subjective forecasts.
% The Dynare auxiliaries store beta times the paper's discounted wage and
% capital-return sums. This function replaces their RE recursions with sums
% implied by the supplied subjective perceived law of motion.
%
% Under infinite-horizon (IH) learning, households do not insert only a
% one-step forecast into an otherwise recursive RE system. They use their PLM
% to form the entire discounted sequence of future wages, capital returns,
% and consumption-related variables appearing in their decision rule. This
% is the implementation of the Eusepi--Preston anticipated-utility mapping:
% beliefs are held fixed while agents evaluate the future path.

n = numel(model.variable_names);
assert(isequal(size(plm.transition),[n n]), ...
    'EPResearch:InvalidPlm','PLM transition must match model dimension.');
lhs = model.current+model.lead*plm.transition;
constant = model.lead*plm.intercept(:);
lag = model.lag;
shock = model.shock;
beta = model.calibration.beta_tilda;

% Replace each Dynare present-value auxiliary equation by
%
%   pv_t = sum_{h=1}^Inf beta^h E_t[target_(t+h)].
%
% evaluate_discounted_forecast returns this sum as q0+q*y_t. Moving it to
% the left gives pv_t-q*y_t=q0. In the residual convention used here that
% means current coefficients [1 on pv, -q on y], constant -q0, and no direct
% lag or shock term. Those effects still enter indirectly through y_t's ALM.
for j = 1:numel(specification.forecast_targets)
    target_index = index_of(model.variable_names, ...
        specification.forecast_targets{j});
    sum_index = index_of(model.variable_names, ...
        specification.present_value_variables{j});
    equation_index = index_of(model.equation_names, ...
        specification.present_value_equations{j});
    target = zeros(1,n);
    target(target_index) = 1;
    forecast = evaluate_discounted_forecast(plm,target,[1 Inf],beta);
    lhs(equation_index,:) = -forecast.coefficients;
    lhs(equation_index,sum_index) = lhs(equation_index,sum_index)+1;
    constant(equation_index) = -forecast.intercept;
    lag(equation_index,:) = 0;
    shock(equation_index,:) = 0;
end

% The original decision equation refers to Dynare's RE present-value
% auxiliaries. Remove those coefficients and insert the subjective IH sums
% directly. The weights below are the coefficients on the three discounted
% forecast objects in the E&P consumption decision rule, expressed using the
% calibration names retained from the replication model.
decision = index_of(model.equation_names,specification.decision_equation);
sum_indices = cellfun(@(name) index_of(model.variable_names,name), ...
    specification.present_value_variables);
lhs(decision,sum_indices) = 0;
p = model.calibration;
weights = [p.beta_tilda-p.c_c, ...
    -p.beta_tilda*p.R_tilda*(p.beta_tilda/p.sigma-p.c_c), ...
    p.c_c*p.beta_tilda*(p.eps_w+p.eps_c*p.chi/(1-p.chi))];
for j = 1:numel(specification.decision_forecast_targets)
    target_index = index_of(model.variable_names, ...
        specification.decision_forecast_targets{j});
    target = zeros(1,n);
    % The model auxiliaries store beta times the paper's sum. Selecting the
    % underlying target with weight 1/beta converts the forecast object back
    % to the normalization required by the decision-equation coefficients.
    target(target_index) = 1/beta;
    forecast = evaluate_discounted_forecast(plm,target,[1 Inf],beta);
    lhs(decision,:) = lhs(decision,:)-weights(j)*forecast.coefficients;
    constant(decision) = constant(decision)-weights(j)*forecast.intercept;
end

% The resulting system has the same generic form as the one-step mapping:
%   lhs*y_t = -constant-lag*y_(t-1)-shock*eps_t.
% Solving it yields the belief-dependent actual law of motion.
assert(rcond(lhs)>specification.rcond_tolerance, ...
    'EPResearch:SingularAlm','Belief-dependent IH system is ill-conditioned.');
alm = struct('intercept',-(lhs\constant),'transition',-(lhs\lag), ...
    'shock_impact',-(lhs\shock));
alm.stability_root = max(abs(eig(alm.transition)));
end

function index = index_of(names,name)
index = find(strcmp(names,name),1);
assert(~isempty(index),'EPResearch:MissingName','Missing name: %s.',name);
end
