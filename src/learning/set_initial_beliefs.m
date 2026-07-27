function learning_model = set_initial_beliefs(learning_model,initialization)
%% SET_INITIAL_BELIEFS Apply a named forecasting-prior treatment.
% This changes only the coefficients agents hold before the first observation.
% The RLS moment matrix remains at its documented population initialization, so
% zero forecast coefficients do not create an artificially singular estimator.

switch string(initialization)
    case "dynare_re"
        % The compiler already supplied the Dynare RE forecasting coefficients.
    case "zero_coefficients"
        learning_model.initial_beliefs.coefficients(:) = 0;
        learning_model.learning.initial_coefficients(:) = 0;
    otherwise
        error('EPResearch:UnknownInitialization', ...
            'Unknown learning initialization: %s.',initialization);
end
learning_model.specification.initialization = string(initialization);
end
