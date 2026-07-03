function [imp_resp_vec, median_imp_resp_vec, low_band, up_band] = run_impulse_responses(config)
%% RUN_IMPULSE_RESPONSES Generate benchmark impulse responses.

if nargin < 1
    config = ir_default_config();
end

setup_ir_paths();

main_config = config.main;
idx = ir_variable_indices();

if ~isfield(main_config, 'output_dir')
    main_config.output_dir = fileparts(mfilename('fullpath'));
end

%%% MAIN FILE FOR GENERATIONG IMPULSE RESPONSES

%% The file generates impulse responses, depending on the initial
%% state of the economy.
T_imp = main_config.impulse_horizon; %% T_imp-1 is the number of periods in the IR

sim_L = main_config.training_sample_length; %% observations discarded before generating the IR

T_tot = sim_L+T_imp; %% total length of simulation

if isfield(main_config, 'n_draws')
    n_draws = main_config.n_draws;
else
    n_draws = config.default_n_draws;
end

%% select percentile
band_up = main_config.band_upper_order_stat;.15*n_draws;

band_down = main_config.band_lower_order_stat;(1-0.15)*n_draws;

store_c = main_config.store_output; %% set == 1 to store matrix of impulse responses

%% Define the IR matrices
n_impulse_resp = idx.ir_series_count; %% number of impulse responses that you want to plot.
%% The order is defines in the Observed_variables file

for j = 1:n_impulse_resp

  imp_resp_vec{j} = zeros(n_draws,T_imp-1);  %%remember, the vector is one unit shorter...

  median_imp_resp_vec{j} = zeros(1,T_imp-1);

  low_band{j} = zeros(1,T_imp-1);

  up_band{j} = zeros(1,T_imp-1);

end

tic

%% Start computing impulse responses
disp('start computing impulse responses')

for ctn = 1:n_draws

  epsZ_full = randn(1,T_tot); %% must correspond to the number of shocks in
  %% the model

  disp(ctn);

  imp_resp_draw = simulate_ir_draw(main_config, epsZ_full, idx);

  for j = 1:n_impulse_resp
    imp_resp_vec{j}(ctn,:) = imp_resp_draw(j,:);
  end

end %% end draws loop

%% Create median impulse responses and bands

%% Median impulse responses
for j1 =1:n_impulse_resp

  for j2 = 1:T_imp-1

    median_imp_resp_vec{j1}(j2) = median(imp_resp_vec{j1}(:,j2));

  end

end

%% Compute bands
for j1 =1:n_impulse_resp

  for j2 = 1:T_imp-1

    vec_sort = sort(imp_resp_vec{j1}(:,j2));

    low_band{j1}(j2) = vec_sort(band_down);  %%$work in progress (define percentile?)...

    up_band{j1}(j2) =  vec_sort(band_up);

  end

end

toc

if store_c == 1
  imp_resp_output.(main_config.output_var) = imp_resp_vec;

  save(fullfile(main_config.output_dir, main_config.output_file), '-struct', 'imp_resp_output');
end

end
