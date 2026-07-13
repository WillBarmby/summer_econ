function [plugin,state] = make_dynare_ih_learning_plugin(model,config,shock_variance)
%% MAKE_DYNARE_IH_LEARNING_PLUGIN Compile named IH learning around a Dynare model.

validate_contract(model,config,shock_variance);
names = model.variable_names;
n = numel(names);
outcome_indices = name_indices(names,config.learned_outcomes,'learned outcome');
capital_index = name_indices(names,{config.state_variable},'state variable');

[re_transition,re_shock] = dynare_re_law(model);
re_intercept = zeros(n,1);
initial_coefficients = [re_intercept(outcome_indices), ...
    re_transition(outcome_indices,capital_index)];
re_covariance = VCV_Model(re_transition,re_shock,shock_variance);
initial_moment_matrix = diag([1,re_covariance(capital_index,capital_index)]);

learning = struct('initial_coefficients',initial_coefficients, ...
    'initial_moment_matrix',initial_moment_matrix,'gain',config.gain, ...
    'rcond_tolerance',config.rcond_tolerance, ...
    'project',make_projection(config,outcome_indices,capital_index));
state = initialize_learning_state(learning);

plugin = struct('name',[model.name ' E&P IH learning'],'model',model, ...
    'learning',learning,'beliefs_to_plm',@(belief_state) expand_plm( ...
    belief_state,re_intercept,re_transition,outcome_indices,capital_index), ...
    'plm_to_alm',@(plm) dynare_ih_plm_to_alm(model,plm,config), ...
    'regressor',@(path,time) [1;path(capital_index,time-1)], ...
    'outcome',@(path,time) path(outcome_indices,time), ...
    're_plm',struct('intercept',re_intercept,'transition',re_transition), ...
    'shock_impact',re_shock,'specification',config);
end

function [transition,shock] = dynare_re_law(model)
dr = model.re.decision_rule;
n = numel(model.variable_names);
transition = zeros(n);
transition(dr.order_var,dr.state_var) = dr.ghx;
shock = zeros(n,size(dr.ghu,2));
shock(dr.order_var,:) = dr.ghu;
end

function plm = expand_plm(state,re_intercept,re_transition,outcomes,capital)
plm = struct('intercept',re_intercept,'transition',re_transition);
plm.intercept(outcomes) = state.coefficients(:,1);
plm.transition(outcomes,capital) = state.coefficients(:,2);
end

function callback = make_projection(config,outcomes,capital)
projected_row = find(outcomes==capital,1);
assert(~isempty(projected_row),'EPIH:InvalidProjection', ...
    'The projected capital equation must be a learned outcome.');
limit = config.projection.absolute_limit;
callback = @project;
    function [candidate,was_projected] = project(candidate,previous)
        was_projected = abs(candidate(projected_row,2))>limit;
        if was_projected
            candidate(projected_row,2) = previous(projected_row,2);
        end
    end
end

function indices = name_indices(names,requested,label)
[found,indices] = ismember(requested,names);
if any(~found)
    error('EPIH:MissingName','Missing %s(s): %s.',label,strjoin(requested(~found),', '));
end
indices = indices(:);
end

function validate_contract(model,config,shock_variance)
validate_canonical_model(model);
required = {'formulation','learned_outcomes','regressors','state_variable', ...
    'observed_but_excluded','forecast_targets','present_value_variables', ...
    'present_value_equations','decision_equation','decision_forecast_targets', ...
    'gain','feedback','update_timing','initialization', ...
    'rcond_tolerance','projection'};
assert(isstruct(config) && isempty(setxor(fieldnames(config),required.')), ...
    'EPIH:InvalidConfig','A complete E&P IH learning config is required.');
assert(config.formulation=="infinite_horizon",'EPIH:InvalidFormulation', ...
    'This compiler requires the infinite-horizon formulation.');
assert(isequal(config.regressors,{'constant','capital_lag'}), ...
    'EPIH:InvalidRegressors','E&P benchmark regressors must be constant and capital_lag.');
assert(config.initialization=="dynare_re",'EPIH:InvalidInitialization', ...
    'E&P benchmark beliefs must initialize from the Dynare RE solution.');
assert(isnumeric(shock_variance) && isscalar(shock_variance) && shock_variance>0, ...
    'EPIH:InvalidShockVariance','shock_variance must be a positive scalar.');
name_indices(model.variable_names,config.learned_outcomes,'learned outcome');
name_indices(model.variable_names,config.forecast_targets,'forecast target');
name_indices(model.variable_names,config.present_value_variables,'present-value variable');
for j=1:numel(config.present_value_equations)
    assert(any(strcmp(model.equation_names,config.present_value_equations{j})), ...
        'EPIH:MissingEquation','Missing equation: %s.',config.present_value_equations{j});
end
assert(any(strcmp(model.equation_names,config.decision_equation)), ...
    'EPIH:MissingEquation','Missing equation: %s.',config.decision_equation);
name_indices(model.variable_names,config.decision_forecast_targets,'decision forecast target');
end
