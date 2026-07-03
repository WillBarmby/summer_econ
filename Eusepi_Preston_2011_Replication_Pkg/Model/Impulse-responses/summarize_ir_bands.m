function [median_imp_resp_vec, low_band, up_band] = summarize_ir_bands(imp_resp_vec, main_config, idx)
%% SUMMARIZE_IR_BANDS Compute median impulse responses and percentile bands.

T_imp = main_config.impulse_horizon;
n_impulse_resp = idx.ir_series_count;

%% select percentile
band_up = main_config.band_upper_order_stat;
% was in og code but were not used there either: .15*size(imp_resp_vec{1},1);
band_down = main_config.band_lower_order_stat;
% was in og code but were not used there either: (1-0.15)*size(imp_resp_vec{1},1);


%% Create median impulse responses and bands
for j = 1:n_impulse_resp
  median_imp_resp_vec{j} = zeros(1,T_imp-1);
  low_band{j} = zeros(1,T_imp-1);
  up_band{j} = zeros(1,T_imp-1);
end

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

end
