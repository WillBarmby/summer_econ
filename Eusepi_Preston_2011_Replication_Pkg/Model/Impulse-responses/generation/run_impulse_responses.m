function [imp_resp_vec, median_imp_resp_vec, low_band, up_band] = run_impulse_responses(config)
%% RUN_IMPULSE_RESPONSES Generate benchmark impulse responses.
%
% Extracted from the former body of Main_imp_resp_Sept_2009.m. The legacy
% file remains as the short user-facing entrypoint.

if nargin ~= 1
    error('IRConfig:Required','run_impulse_responses requires one complete configuration.');
end

setup_ir_paths();
validate_ir_config(config);

main_config = config.main;
idx = ir_variable_indices();

%%% MAIN FILE FOR GENERATIONG IMPULSE RESPONSES

%% The file generates impulse responses, depending on the initial
%% state of the economy.
T_imp = main_config.impulse_horizon; %% T_imp-1 is the number of periods in the IR

sim_L = main_config.training_sample_length; %% observations discarded before generating the IR

T_tot = sim_L+T_imp; %% total length of simulation

n_draws = main_config.n_draws;

%% select percentile
store_c = main_config.store_output; %% set == 1 to store matrix of impulse responses

%% Define the IR matrices
n_impulse_resp = idx.ir_series_count; %% number of impulse responses that you want to plot.
%% The order is defines in the Observed_variables file

for j = 1:n_impulse_resp

  imp_resp_vec{j} = zeros(n_draws,T_imp-1);  %%remember, the vector is one unit shorter...

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

[median_imp_resp_vec, low_band, up_band] = summarize_ir_bands(imp_resp_vec, main_config, idx);

toc

if store_c == 1
  save_ir_output(main_config, imp_resp_vec);
end

end
