function [plugin,state] = make_dynare_ee_learning_plugin(model,config,shock_variance)
%% MAKE_DYNARE_EE_LEARNING_PLUGIN Compile an explicit Dynare EE specification.

validate_canonical_model(model);
assert(any(strcmp(model.backend,{'dynare-7.1','dynare-7.1-first-order'})), ...
    'Dynare EE requires a Dynare 7.1 canonical model.');
required={'variant','learned_outcomes','regressors','state_variable', ...
    'observed_but_excluded','gain','initialization','update_timing','projection'};
assert(isstruct(config) && isempty(setxor(fieldnames(config),required.')), ...
    'EPEE:InvalidConfig','A complete EE learning configuration is required.');
assert(isequal(config.regressors,{'constant','capital_lag'}) && ...
    config.initialization=="dynare_re" && config.update_timing=="decide_then_update");
learned_names=config.learned_outcomes;
[found,outcomes]=ismember(learned_names,model.variable_names);
assert(all(found),'Dynare EE model is missing a declared learned outcome.');
state_variable=find(strcmp(model.variable_names,config.state_variable),1);
assert(~isempty(state_variable),'Dynare EE model is missing its declared state variable.');
[found_shocks,~]=ismember(config.observed_but_excluded,model.shock_names);
assert(all(found_shocks),'Dynare EE model is missing a declared observed shock.');
assert(strcmp(config.projection.outcome,config.state_variable) && ...
    config.projection.action=="reject_update", ...
    'Dynare EE currently projects the recursive state by rejecting its update.');
[has_projected_outcome,projected_row]=ismember( ...
    config.projection.outcome,learned_names);
assert(has_projected_outcome, ...
    'The projected state equation must be a learned outcome.');
[re_transition,re_shock]=dynare_re_law(model);
re_intercept=zeros(numel(model.variable_names),1);
coefficients=[re_intercept(outcomes),re_transition(outcomes,state_variable)];
covariance=VCV_Model(re_transition,re_shock,shock_variance);
learning=struct('initial_coefficients',coefficients, ...
    'initial_moment_matrix',diag([1,covariance(state_variable,state_variable)]), ...
    'gain',config.gain, ...
    'rcond_tolerance',model_simul_default_options().r_matrix_tolerance, ...
    'project',@project_state);
state=initialize_learning_state(learning);

plugin=struct('name',[model.name ' EE learning'],'model',model, ...
    'learning',learning,'beliefs_to_plm',@expand_plm, ...
    'plm_to_alm',@(plm) plm_to_alm_linear(model,plm), ...
    'regressor',@(path,time) [1;path(state_variable,time-1)], ...
    'outcome',@(path,time) path(outcomes,time), ...
    're_plm',struct('intercept',re_intercept,'transition',re_transition), ...
    'shock_impact',re_shock,'learned_outcomes',{learned_names}, ...
    'specification',config);

    function plm=expand_plm(beliefs)
        plm=struct('intercept',re_intercept,'transition',re_transition);
        plm.intercept(outcomes)=beliefs.coefficients(:,1);
        plm.transition(outcomes,state_variable)=beliefs.coefficients(:,2);
    end

    function [candidate,projected]=project_state(candidate,previous)
        projected=abs(candidate(projected_row,2))>config.projection.absolute_limit;
        if projected
            candidate(projected_row,2)=previous(projected_row,2);
        end
    end
end

function [transition,shock]=dynare_re_law(model)
dr=model.re.decision_rule;
n=numel(model.variable_names);
transition=zeros(n);
transition(dr.order_var,dr.state_var)=dr.ghx;
shock=zeros(n,size(dr.ghu,2));
shock(dr.order_var,:)=dr.ghu;
end
