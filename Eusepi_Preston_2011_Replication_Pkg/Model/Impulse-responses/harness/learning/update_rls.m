function [state, diagnostic] = update_rls(state, regressor, outcome, config)
%% UPDATE_RLS Perform one model-independent learning update.
% Notation follows standard adaptive-learning/RLS conventions:
%
%   y_t = B_t x_t + error_t
%
% where:
%   B_t is the matrix of estimated forecasting coefficients;
%   x_t is the regressor vector;
%   R_t is the estimated second-moment matrix of regressors,
%       approximately E[x_t x_t'].
%
% The recursive updates are:
%
%   R_t = R_{t-1} + g_t * (x_t*x_t' - R_{t-1})
%
%   B_t = B_{t-1} ...
%         + g_t * (y_t - B_{t-1}*x_t) * (R_t\x_t)'
%
% Here g_t is the learning gain.

x = regressor(:);
y = outcome(:);

num_outcomes = numel(y);
num_regressors = numel(x);

assert(size(state.coefficients, 1) == num_outcomes, ...
    'Coefficient rows must equal the number of outcomes.');

assert(size(state.coefficients, 2) == num_regressors, ...
    'Coefficient columns must equal the number of regressors.');

switch lower(config.gain.type)
    case 'constant'
        gain = config.gain.value;

    case 'decreasing'
        gain = 1 / (state.observations + config.gain.offset + 1);

    otherwise
        error('Unknown gain type: %s', config.gain.type);
end

old_R = state.moment_matrix;
new_R = old_R + gain * (x * x' - old_R);

reciprocal_condition = rcond(new_R); % Determines if the matrix is safe to solve against. How close to singular is it?

% Return early if matrix is too close to singular
if reciprocal_condition < config.rcond_tolerance
    state.invalid = true;
    diagnostic = struct( ...
        'gain', gain, ...
        'rcond', reciprocal_condition, ...
        'prediction_error', NaN(size(y)), ...
        'projected', false);

    return
end

% Update state
old_B = state.coefficients;
prediction = old_B * x;
prediction_error = y - prediction;

scaled_regressor = new_R \ x;
proposed_B = old_B ...
    + gain * prediction_error * scaled_regressor';

projected = false;
new_B = proposed_B;

if isfield(config, 'project') && ~isempty(config.project)
    [new_B, projected] = config.project(proposed_B, old_B);
end

state.coefficients = new_B;
state.moment_matrix = new_R;
state.observations = state.observations + 1;

if projected
    state.projection_events = state.projection_events + 1;
end

diagnostic = struct( ...
    'gain', gain, ...
    'rcond', reciprocal_condition, ...
    'prediction_error', prediction_error, ...
    'projected', projected);

end