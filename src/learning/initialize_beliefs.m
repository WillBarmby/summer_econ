function beliefs = initialize_beliefs(config)
%% INITIALIZE_BELIEFS Create the mutable state used by recursive learning.
% coefficients is the current perceived-law parameter matrix and
% moment_matrix estimates E[x_t*x_t']. The counters make projection and
% failure behavior observable in saved experiment artifacts.

beliefs = struct('coefficients',config.initial_coefficients, ...
    'moment_matrix',config.initial_moment_matrix,'observations',0, ...
    'projection_events',0,'invalid',false);
end
