function [imp_resp_vec, median_imp_resp_vec, low_band, up_band, draw_results] = run_impulse_responses(config)
%% RUN_IMPULSE_RESPONSES Generate benchmark impulse responses.
%
% Extracted from the former body of Main_imp_resp_Sept_2009.m. The legacy
% file remains as the short user-facing entrypoint.

if nargin ~= 1
    error('IRConfig:Required','run_impulse_responses requires one complete configuration.');
end

function [medians,low_band,up_band] = summarize_ir_bands(values,main_config,idx)
horizon = main_config.impulse_horizon-1;
medians = cell(1,idx.ir_series_count);
low_band = cell(1,idx.ir_series_count);
up_band = cell(1,idx.ir_series_count);
for series = 1:idx.ir_series_count
    medians{series} = median(values{series},1);
    sorted = sort(values{series},1);
    low_band{series} = sorted(main_config.band_lower_order_stat,1:horizon);
    up_band{series} = sorted(main_config.band_upper_order_stat,1:horizon);
end
end

function save_ir_output(main_config,imp_resp_vec)
output.(main_config.output_var) = imp_resp_vec;
save(fullfile(main_config.output_dir,main_config.output_file),'-struct','output');
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

  draw_results{ctn} = simulate_ir_draw(main_config, epsZ_full, idx);

  if draw_results{ctn}.status == "completed"
    for j = 1:n_impulse_resp
      imp_resp_vec{j}(ctn,:) = draw_results{ctn}.ir_series(j,:);
    end
  else
    for j = 1:n_impulse_resp
      imp_resp_vec{j}(ctn,:) = NaN;
    end
  end

end %% end draws loop

[median_imp_resp_vec, low_band, up_band] = summarize_ir_bands(imp_resp_vec, main_config, idx);

toc

if store_c == 1
  save_ir_output(main_config, imp_resp_vec);
end

end
