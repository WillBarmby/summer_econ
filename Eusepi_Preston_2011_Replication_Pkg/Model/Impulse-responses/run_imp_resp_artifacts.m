function run_imp_resp_artifacts
%% GENERATE IMPULSE RESPONSE ARTIFACTS FOR PLOTTING

model_dir = setup_ir_paths();
config = make_ir_config();
config.main.store_output = false;

%% Learning case
config.main.learning = true;
[imp_resp_vec_L,~,~,~,learning_draws] = run_impulse_responses(config);

%% Rational expectations case
config.main.learning = false;
[imp_resp_vec_R,~,~,~,re_draws] = run_impulse_responses(config);

save(fullfile(model_dir, 'imp_resp_bench_artifacts.mat'), ...
    'imp_resp_vec_L', 'imp_resp_vec_R', 'learning_draws', 're_draws');

end
