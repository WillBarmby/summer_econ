function run_imp_resp_artifacts
%% GENERATE IMPULSE RESPONSE ARTIFACTS FOR PLOTTING

model_dir = fileparts(mfilename('fullpath'));
old_dir = pwd;
cleanup = onCleanup(@() cd(old_dir));

cd(model_dir);

%% Learning case
skip_clear = 1;
imp_resp_learning = 1;
imp_resp_store = 0;

run('Main_imp_resp_Sept_2009.m');

imp_resp_vec_L = imp_resp_vec;

clearvars -except model_dir old_dir cleanup imp_resp_vec_L

%% Rational expectations case
skip_clear = 1;
imp_resp_learning = 0;
imp_resp_store = 0;

run('Main_imp_resp_Sept_2009.m');

imp_resp_vec_R = imp_resp_vec;

save(fullfile(model_dir, 'imp_resp_bench_artifacts.mat'), ...
    'imp_resp_vec_L', 'imp_resp_vec_R');

end
