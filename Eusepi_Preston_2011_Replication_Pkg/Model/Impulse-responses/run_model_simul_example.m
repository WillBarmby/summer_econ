% run_model_simul_example.m
% Example parameterization for simulate_model_paths.
% These are the standalone values that were previously commented in the
% simulation function.

setup_ir_paths();
config = make_ir_config();
example = config.simulation_example;

exp_gen = example.expectations_enabled;
imp_resp = example.impulse_response_enabled;
full = example.full_sample;
epsZ_imp1 = example.initial_shock;
ini1 = example.initial_regressors;
ini2 = example.initial_precision;
ini3 = example.initial_state;
ini4 = example.initial_omega_c;
ini5 = example.initial_omega_0;
sim_L = example.training_sample_length;
x = example.model_param;
S_mat = example.shock_scale';
fb = example.feedback;
lern = example.learning;
epsZ = randn(1, example.shock_sample_length);

[Y_var, Exp_R_1Q, Exp_R_3Q, Exp_w_1Q, Exp_w_2Q, Exp_w_3Q, ...
    Exp_w_4Q, Exp_rk_1Q, Exp_rk_2Q, Exp_rk_3Q, Exp_rk_4Q, ...
    Regressors_ini, R_mat_ini, state_ini, OMEGA_c_ini, OMEGA_0_ini, ...
    invalid_simulation] = ...
    simulate_model_paths(x, S_mat, fb, lern, exp_gen, imp_resp, full, ...
    epsZ_imp1, ini1, ini2, ini3, ini4, ini5, sim_L, epsZ, ...
    config.main.explosion_policy);
