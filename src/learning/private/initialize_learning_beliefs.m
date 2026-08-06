function beliefs = initialize_learning_beliefs(solution,specification,contract)
%% INITIALIZE_LEARNING_BELIEFS Construct coefficients and RLS moments.

m = numel(contract.learned_indices);
k = numel(contract.regressor_names);
coefficients = zeros(m,k);
for column = 1:k
    switch contract.regressor_kinds(column)
        case "constant"
            coefficients(:,column) = ...
                solution.intercept(contract.learned_indices);
        case "lagged_variable"
            coefficients(:,column) = solution.transition( ...
                contract.learned_indices,contract.regressor_indices(column));
    end
end
coefficients = specification.initialization.coefficients.scale*coefficients;

moment_matrix = stationary_regressor_moments( ...
    solution,specification.initialization.moments.shock_covariance,contract);
beliefs = struct( ...
    'coefficients',coefficients, ...
    'moment_matrix',moment_matrix, ...
    'observations',0, ...
    'projection_events',0, ...
    'invalid',false);
end

function moments = stationary_regressor_moments(solution,shock_covariance,contract)
transition = solution.transition;
if max(abs(eig(transition)))>=1
    error('AdaptiveLearning:InvalidLearningSpecification', ...
        'Stationary-RE initialization requires a stable RE transition.');
end
mean_value = (eye(size(transition))-transition)\solution.intercept;
innovation = solution.shock*shock_covariance*solution.shock';
covariance = zeros(size(transition));
converged = false;
for iteration = 1:100000
    updated = transition*covariance*transition'+innovation;
    if norm(updated-covariance,'fro') <= ...
            1e-13*max(1,norm(updated,'fro'))
        covariance = (updated+updated')/2;
        converged = true;
        break
    end
    covariance = updated;
end
if ~converged
    error('AdaptiveLearning:InvalidLearningSpecification', ...
        'Stationary regressor moments did not converge.');
end

k = numel(contract.regressor_names);
moments = zeros(k);
for row = 1:k
    for column = 1:k
        moments(row,column) = regressor_moment( ...
            row,column,mean_value,covariance,contract);
    end
end
moments = (moments+moments')/2;
end

function value = regressor_moment(row,column,mean_value,covariance,contract)
row_constant = contract.regressor_kinds(row)=="constant";
column_constant = contract.regressor_kinds(column)=="constant";
if row_constant && column_constant
    value = 1;
elseif row_constant
    value = mean_value(contract.regressor_indices(column));
elseif column_constant
    value = mean_value(contract.regressor_indices(row));
else
    row_index = contract.regressor_indices(row);
    column_index = contract.regressor_indices(column);
    value = covariance(row_index,column_index)+ ...
        mean_value(row_index)*mean_value(column_index);
end
end
