function system = assemble_learning_system( ...
    model,solution,specification,contract,initial_beliefs)
%% ASSEMBLE_ONE_STEP_LEARNING_SYSTEM Create the compiled public handoff.

system = struct( ...
    'variable_names',{model.variable_names}, ...
    'shock_names',{model.shock_names}, ...
    'learned_variables',{specification.learned_variables}, ...
    'regressor_names',{contract.regressor_names}, ...
    'initial_beliefs',initial_beliefs, ...
    'belief_to_plm',make_belief_to_plm( ...
        solution.intercept,solution.transition,contract), ...
    'plm_to_alm',make_plm_to_alm(model,contract.expectation, ...
        specification.estimator.rcond_tolerance), ...
    'regressor',make_regressor(contract), ...
    'outcome',make_outcome(contract.learned_indices), ...
    'updater',make_rls_updater( ...
        specification.gain,specification.estimator.rcond_tolerance, ...
        specification.projection,contract));
end

function callback = make_belief_to_plm(intercept,transition,contract)
callback = @belief_to_plm;
    function plm = belief_to_plm(beliefs)
        expected = [numel(contract.learned_indices) ...
            numel(contract.regressor_names)];
        if ~isstruct(beliefs) || ~isfield(beliefs,'coefficients') || ...
                ~isequal(size(beliefs.coefficients),expected)
            error('AdaptiveLearning:InvalidLearningSystem', ...
                'Belief coefficients do not match the compiled dimensions.');
        end
        plm = struct('intercept',intercept,'transition',transition);
        for column = 1:numel(contract.regressor_names)
            if contract.regressor_kinds(column)=="constant"
                plm.intercept(contract.learned_indices) = ...
                    beliefs.coefficients(:,column);
            else
                plm.transition(contract.learned_indices, ...
                    contract.regressor_indices(column)) = ...
                    beliefs.coefficients(:,column);
            end
        end
    end
end

function callback = make_plm_to_alm(model,expectation,tolerance)
if expectation.method=="one_step"
    callback = make_one_step_alm( ...
        model.current,model.lag,model.lead,model.shock,tolerance);
else
    callback = make_infinite_horizon_alm(model,expectation,tolerance);
end
end

function callback = make_one_step_alm(current,lag,lead,shock,tolerance)
callback = @one_step_alm;
    function alm = one_step_alm(plm)
        n = size(current,1);
        if ~isstruct(plm) || ~isscalar(plm) || ...
                ~all(isfield(plm,{'intercept','transition'})) || ...
                ~isequal(size(plm.intercept),[n 1]) || ...
                ~isequal(size(plm.transition),[n n])
            error('AdaptiveLearning:InvalidLearningSystem', ...
                'PLM dimensions do not match the structural model.');
        end
        lhs = current+lead*plm.transition;
        if rcond(lhs)<tolerance
            error('AdaptiveLearning:SingularALM', ...
                'Beliefs imply a singular one-step actual law.');
        end
        alm = struct( ...
            'intercept',-(lhs\(lead*plm.intercept)), ...
            'transition',-(lhs\lag), ...
            'shock',-(lhs\shock));
    end
end

function callback = make_infinite_horizon_alm(model,expectation,tolerance)
current = model.current;
lead = model.lead;
base_lag = model.lag;
base_shock = model.shock;
n = size(current,1);
callback = @infinite_horizon_alm;
    function alm = infinite_horizon_alm(plm)
        validate_plm(plm,n);
        lhs = current+lead*plm.transition;
        constant = lead*plm.intercept;
        lag = base_lag;
        shock = base_shock;
        for j = 1:numel(expectation.present_value_target_indices)
            target = zeros(1,n);
            target(expectation.present_value_target_indices(j)) = ...
                expectation.present_value_target_scales(j);
            forecast = evaluate_discounted_forecast( ...
                plm,target,expectation.discount);
            equation = expectation.present_value_equation_indices(j);
            variable = expectation.present_value_variable_indices(j);
            lhs(equation,:) = -forecast.coefficients;
            lhs(equation,variable) = lhs(equation,variable)+1;
            constant(equation) = -forecast.intercept;
            lag(equation,:) = 0;
            shock(equation,:) = 0;
        end
        decision = expectation.decision_equation_index;
        lhs(decision,expectation.decision_remove_indices) = 0;
        for j = 1:numel(expectation.decision_target_indices)
            target = zeros(1,n);
            target(expectation.decision_target_indices(j)) = 1;
            forecast = evaluate_discounted_forecast( ...
                plm,target,expectation.discount);
            weight = expectation.decision_weights(j);
            lhs(decision,:) = lhs(decision,:)- ...
                weight*forecast.coefficients;
            constant(decision) = constant(decision)- ...
                weight*forecast.intercept;
        end
        if rcond(lhs)<tolerance
            error('AdaptiveLearning:SingularALM', ...
                'Beliefs imply a singular infinite-horizon actual law.');
        end
        alm = struct( ...
            'intercept',-(lhs\constant), ...
            'transition',-(lhs\lag), ...
            'shock',-(lhs\shock));
    end
end

function validate_plm(plm,n)
if ~isstruct(plm) || ~isscalar(plm) || ...
        ~all(isfield(plm,{'intercept','transition'})) || ...
        ~isequal(size(plm.intercept),[n 1]) || ...
        ~isequal(size(plm.transition),[n n])
    error('AdaptiveLearning:InvalidLearningSystem', ...
        'PLM dimensions do not match the structural model.');
end
end

function callback = make_regressor(contract)
callback = @regressor;
    function value = regressor(path,time)
        value = zeros(numel(contract.regressor_names),1);
        for j = 1:numel(value)
            if contract.regressor_kinds(j)=="constant"
                value(j) = 1;
            else
                value(j) = path(contract.regressor_indices(j),time-1);
            end
        end
    end
end

function callback = make_outcome(learned_indices)
callback = @(path,time) path(learned_indices,time);
end

function callback = make_rls_updater( ...
    gain_policy,rcond_tolerance,projection,contract)
callback = @update;
    function [beliefs,diagnostic] = update(beliefs,x,y)
        x = x(:);
        y = y(:);
        if ~isequal(size(beliefs.coefficients),[numel(y) numel(x)]) || ...
                ~isequal(size(beliefs.moment_matrix),[numel(x) numel(x)])
            error('AdaptiveLearning:InvalidLearningSystem', ...
                'Observation dimensions do not match compiled beliefs.');
        end
        gain = current_gain(gain_policy,beliefs.observations);
        updated_moment = beliefs.moment_matrix+gain* ...
            (x*x'-beliefs.moment_matrix);
        condition = rcond(updated_moment);
        if condition<rcond_tolerance
            beliefs.invalid = true;
            diagnostic = struct('gain',gain,'rcond',condition, ...
                'prediction_error',NaN(size(y)),'projected',false);
            return
        end
        previous = beliefs.coefficients;
        prediction_error = y-previous*x;
        candidate = previous+gain*prediction_error*(updated_moment\x)';
        projected = false;
        for j = 1:numel(contract.projection_rows)
            row = contract.projection_rows(j);
            column = contract.projection_columns(j);
            limit = projection(j).limit;
            if abs(candidate(row,column))>limit
                candidate(row,column) = previous(row,column);
                projected = true;
            end
        end
        beliefs.coefficients = candidate;
        beliefs.moment_matrix = updated_moment;
        beliefs.observations = beliefs.observations+1;
        beliefs.projection_events = beliefs.projection_events+double(projected);
        diagnostic = struct('gain',gain,'rcond',condition, ...
            'prediction_error',prediction_error,'projected',projected);
    end
end

function gain = current_gain(policy,observations)
if string(policy.type)=="constant"
    gain = policy.value;
else
    gain = 1/(observations+policy.offset+1);
end
end
