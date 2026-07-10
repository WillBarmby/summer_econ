function [state, diagnostic] = update_rls(state, regressor, outcome, config)
%% UPDATE_RLS One model-independent recursive least-squares update.

x = regressor(:);
y = outcome(:);
assert(size(state.coefficients,1) == numel(y));
assert(size(state.coefficients,2) == numel(x));
if strcmpi(config.gain.type,'constant')
    gain = config.gain.value;
else
    gain = 1/(state.observations+config.gain.offset+1);
end
R1 = state.moment_matrix+gain*(x*x'-state.moment_matrix);
condition = rcond(R1);
if condition < config.rcond_tolerance
    state.invalid = true;
    diagnostic = struct('gain',gain,'rcond',condition,'prediction_error',NaN(size(y)), ...
        'projected',false);
    return
end
error = y-state.coefficients*x;
B1 = state.coefficients+gain*(R1\x)*error';
B1 = B1';
projected = false;
if isfield(config,'project') && ~isempty(config.project)
    [B1,projected] = config.project(B1,state.coefficients);
end
state.coefficients = B1;
state.moment_matrix = R1;
state.observations = state.observations+1;
state.projection_events = state.projection_events+double(projected);
diagnostic = struct('gain',gain,'rcond',condition,'prediction_error',error, ...
    'projected',projected);
end
