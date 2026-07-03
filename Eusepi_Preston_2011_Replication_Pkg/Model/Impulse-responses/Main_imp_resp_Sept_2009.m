if exist('skip_clear','var') ~= 1
  clear all;%clc
end

model_dir = setup_ir_paths();
config = ir_default_config();

if exist('imp_resp_n_draws','var') == 1
  config.main.n_draws = imp_resp_n_draws;
end

if exist('imp_resp_store','var') == 1
  config.main.store_output = imp_resp_store;
end

if exist('imp_resp_learning','var') == 1
  config.main.learning = imp_resp_learning;
end

if exist('imp_resp_output_file','var') == 1
  config.main.output_file = imp_resp_output_file;
end

if exist('imp_resp_output_var','var') == 1
  config.main.output_var = imp_resp_output_var;
end

config.main.output_dir = model_dir;

[imp_resp_vec, median_imp_resp_vec, low_band, up_band] = run_impulse_responses(config);
