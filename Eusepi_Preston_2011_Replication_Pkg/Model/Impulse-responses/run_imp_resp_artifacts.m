function run_imp_resp_artifacts
%% GENERATE IMPULSE RESPONSE ARTIFACTS FOR PLOTTING

model_dir = fileparts(mfilename('fullpath'));
old_dir = pwd;
cleanup = onCleanup(@() cd(old_dir));

cd(model_dir);

%% Learning case
skip_clear = 1;
imp_resp_learning = 1;
imp_resp_output_file = 'COEFF_STORE_impresp_mat_learn_bench2.mat';
imp_resp_output_var = 'imp_resp_vec_RBC_learn_bench2';

run('Main_imp_resp_Sept_2009.m');

clearvars -except model_dir old_dir cleanup

%% Rational expectations case
skip_clear = 1;
imp_resp_learning = 0;
imp_resp_output_file = 'COEFF_STORE_impresp_mat_ree_bench.mat';
imp_resp_output_var = 'imp_resp_vec_RBC_ree_bench';

run('Main_imp_resp_Sept_2009.m');

end
