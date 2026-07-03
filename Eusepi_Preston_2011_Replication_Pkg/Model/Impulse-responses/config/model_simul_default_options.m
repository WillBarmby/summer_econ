function options = model_simul_default_options()
%% MODEL_SIMUL_DEFAULT_OPTIONS Defaults used by Model_Simul_Oct_2009.

options = struct();

options.generate_shocks = 0; %% set to 1 to generate new sequence of shocks

options.constant_gain = 1; %% set == 1 if constant gain (active if learning ==1)

options.stochastic_gradient = 0; %% set == 1 is stochastig gradient (active if learning ==1)

options.include_constant = 1; %% set == 1 if want to include the constant in the regression.

options.projection_facility = 0; %% set == 1 to activate projection facility
                                 %% NOTE: also computes the beliefs' distribution in the case
                                 %% of no-feedbacks from learning
                                 %% (active if learning==1)

options.projection_facility_tightness = 8; %% defines how tight is the projection facility
                                           %% (active if learning ==1)

options.store_coefficients = 0; %% set == 1 to store the coefficients (active if learning==1)

options.simulation_length = 55000; %% length of the simulation (active if gen_shocks ==1)

options.initial_gain = 500; %% initial gain for RLS (active if learning==1)

options.r_matrix_tolerance = 1.0856345e-010; %% if RCOND of inv(R) is above R_mat_tol,
                                             %% the learning algorithm switches to SG
                                             %% (active if learning==1)

options.initial_conditions_defined = 0; %% set == 1 if initial conditions for calculating REE are
                                        %% already defined

options.expectation_horizons = [1 2 40 120]; %% vector containing the expectations horizons
                                             %% (active if exp_gen == 1)

end
