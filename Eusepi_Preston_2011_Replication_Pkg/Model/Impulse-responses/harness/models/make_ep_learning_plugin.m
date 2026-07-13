function [plugin,state] = make_ep_learning_plugin(param,shock_variance)
%% MAKE_EP_LEARNING_PLUGIN Adapt E&P learning to the generic engine.
% The plugin stores the model-specific operations needed by
% simulate_learning_path. The separately returned state stores the mutable
% recursive-least-squares (RLS) beliefs for one simulation.

if nargin~=2
    error('LegacyEP:RequiredArguments', ...
        'param and shock_variance must both be supplied explicitly.');
end

% Build the structural model and its rational-expectations equilibrium (REE).
model=load_legacy_ep_model(param);

% Agents estimate an intercept and a lagged-capital coefficient for each of
% the first seven variables. All other PLM coefficients remain at the REE.
num_learned_equations=7;
re_plm_intercept=model.re.plm_intercept;
re_plm_transition=model.re.plm_transition;
capital_index=find(strcmp(model.variable_names,'capital'),1);
assert(~isempty(capital_index),'The E&P model must contain capital.');

initial_coefficients=[ ...
    re_plm_intercept(1:num_learned_equations), ...
    re_plm_transition(1:num_learned_equations,capital_index)];

% Initialize E[x_t*x_t'] for x_t=[1; capital_(t-1)]. The model is written
% in deviations from steady state, so capital has mean zero. Its variance
% is initialized to the unconditional variance implied by the REE.
initial_moment_matrix=eye(2);
re_variable_covariance=VCV_Model( ...
    model.re.transition,model.re.shock_impact,shock_variance);
initial_moment_matrix(2,2)= ...
    re_variable_covariance(capital_index,capital_index);

learning=struct( ...
    'initial_coefficients',initial_coefficients, ...
    'initial_moment_matrix',initial_moment_matrix, ...
    'gain',struct('type','constant','value',param(6),'offset',500), ...
    'rcond_tolerance',model_simul_default_options().r_matrix_tolerance, ...
    'project',@(proposed,previous) enforce_capital_persistence_bound( ...
    proposed,previous,capital_index));
state=initialize_learning_state(learning);

% These fields form the model-specific interface used by the generic
% adaptive-learning simulator.
plugin=struct();
plugin.name='E&P legacy-compatible learning';
plugin.model=model;
plugin.learning=learning;
plugin.beliefs_to_plm=@(belief_state) expand_beliefs_to_plm( ...
    belief_state,re_plm_intercept,re_plm_transition,capital_index, ...
    num_learned_equations);
plugin.plm_to_alm=@(plm) evaluate_legacy_alm(model,plm);
plugin.regressor=@(model_path,time_index) ...
    [1;model_path(capital_index,time_index-1)];
plugin.outcome=@(model_path,time_index) ...
    model_path(1:num_learned_equations,time_index);
plugin.re_plm=struct( ...
    'intercept',re_plm_intercept,'transition',re_plm_transition);
end

function plm=expand_beliefs_to_plm(belief_state,re_intercept, ...
    re_transition,capital_index,num_learned_equations)
% Start from the full REE PLM and replace only the coefficients being learned.
plm=struct('intercept',re_intercept,'transition',re_transition);
plm.intercept(1:num_learned_equations)=belief_state.coefficients(:,1);
plm.transition(1:num_learned_equations,capital_index)= ...
    belief_state.coefficients(:,2);
end

function alm=evaluate_legacy_alm(model,plm)
% Map agents' perceived law of motion (PLM) into the resulting actual law
% of motion (ALM) using the original Eusepi-Preston solver.
[alm_intercept,alm_transition,alm_shock_impact]=ALM_fun( ...
    model.expectation_matrices,model.transformed_shock, ...
    model.inv_current,plm.intercept,plm.transition, ...
    model.forecast_horizon,model.discounts);
alm=struct( ...
    'intercept',alm_intercept, ...
    'transition',alm_transition, ...
    'shock_impact',alm_shock_impact);
end

function [proposed_coefficients,projected]= ...
    enforce_capital_persistence_bound(proposed_coefficients, ...
    previous_coefficients,capital_index)
% Match the legacy safeguard: reject an update that would make the
% perceived capital autoregressive coefficient exceed 0.99 in magnitude.
projected=false;
if capital_index<=size(proposed_coefficients,1) && ...
        abs(proposed_coefficients(capital_index,2))>0.99
    proposed_coefficients(capital_index,2)= ...
        previous_coefficients(capital_index,2);
    projected=true;
end
end
