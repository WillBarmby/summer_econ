function [beliefs,diagnostic] = update_beliefs_rls( ...
    beliefs,regressor,outcome,config)
%% UPDATE_BELIEFS_RLS Perform one recursive least-squares learning update.
% For y_t=B_t*x_t+error_t, update the regressor moment R and coefficients B:
%   R_t = R_(t-1)+g_t*(x_t*x_t'-R_(t-1))
%   B_t = B_(t-1)+g_t*(y_t-B_(t-1)*x_t)*(R_t\x_t)'.
% Constant gain discounts old observations geometrically; decreasing gain
% approaches ordinary least squares. The update uses R_t (after observing
% x_t), matching the timing in the retained E&P implementation.

x = regressor(:);
y = outcome(:);
assert(isequal(size(beliefs.coefficients),[numel(y) numel(x)]), ...
    'EPResearch:RlsDimensions','Belief dimensions do not match the observation.');
switch lower(config.gain.type)
    case 'constant'
        gain = config.gain.value;
    case 'decreasing'
        gain = 1/(beliefs.observations+config.gain.offset+1);
    otherwise
        error('EPResearch:UnknownGain','Unknown gain type: %s',config.gain.type);
end

new_moment = beliefs.moment_matrix+gain* ...
    (x*x'-beliefs.moment_matrix);
condition = rcond(new_moment);
if condition<config.rcond_tolerance
    beliefs.invalid = true;
    diagnostic = struct('gain',gain,'rcond',condition, ...
        'prediction_error',NaN(size(y)),'projected',false);
    return
end
old_coefficients = beliefs.coefficients;
error_value = y-old_coefficients*x;
candidate = old_coefficients+gain*error_value*(new_moment\x)';
projected = false;
if isfield(config,'project') && ~isempty(config.project)
    [candidate,projected] = config.project(candidate,old_coefficients);
end
beliefs.coefficients = candidate;
beliefs.moment_matrix = new_moment;
beliefs.observations = beliefs.observations+1;
beliefs.projection_events = beliefs.projection_events+double(projected);
diagnostic = struct('gain',gain,'rcond',condition, ...
    'prediction_error',error_value,'projected',projected);
end
