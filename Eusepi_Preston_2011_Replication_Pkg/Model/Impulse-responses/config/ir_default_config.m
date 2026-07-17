function config = ir_default_config()
%% IR_DEFAULT_CONFIG Central defaults for impulse-response scripts.

config = struct();

config.baseline_seed = 20260701;
config.default_n_draws = 100;

config.main = struct();
config.main.impulse_horizon = 64;
config.main.training_sample_length = 2000;
config.main.output_file = 'COEFF_STORE_impresp_mat_learn_bench2.mat';
config.main.output_var = 'imp_resp_vec_RBC_learn_bench2';
config.main.store_output = true;
config.main.learning = true;
config.main.expectations_enabled = true;
config.main.impulse_response_enabled = true;
config.main.feedback = true;
config.main.shock_scale = exp(-0.034);
config.main.normalized_shock_size = 1;
config.main.band_upper_order_stat = 1;
config.main.band_lower_order_stat = 1;
config.main.model_param = [1; 0; 1; 1; 0.0001; 0.002];
config.main.n_draws = config.default_n_draws;
config.main.output_dir = fileparts(fileparts(mfilename('fullpath')));
config.main.explosion_policy = struct( ...
    'magnitude_limit', 1000, ...
    'reject_nonfinite', true, ...
    'variable_indices', 1:13);

config.simulation_example = struct();
config.simulation_example.expectations_enabled = true;
config.simulation_example.impulse_response_enabled = false;
config.simulation_example.full_sample = true;
config.simulation_example.initial_shock = 1;
config.simulation_example.initial_regressors = 0;
config.simulation_example.initial_precision = 0;
config.simulation_example.initial_state = 0;
config.simulation_example.initial_omega_c = 0;
config.simulation_example.initial_omega_0 = 0;
config.simulation_example.training_sample_length = 1;
config.simulation_example.shock_scale = exp(-0.034);
config.simulation_example.feedback = true;
config.simulation_example.learning = true;
config.simulation_example.shock_sample_length = 22000;
config.simulation_example.model_param = [1; 0; 1; 1; 0.01; 0.0049];

end
