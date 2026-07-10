function state = initialize_learning_state(config)
%% INITIALIZE_LEARNING_STATE Create reusable RLS state.

state.coefficients = config.initial_coefficients;
state.moment_matrix = config.initial_moment_matrix;
state.observations = 0;
state.projection_events = 0;
state.invalid = false;
end
