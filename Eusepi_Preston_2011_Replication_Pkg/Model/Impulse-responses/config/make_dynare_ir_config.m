function experiment = make_dynare_ir_config()
%% MAKE_DYNARE_IR_CONFIG Explicit Dynare quantities experiment.

experiment = struct();
experiment.random_seed = 20260701;
experiment.draw_count = 100;
experiment.training_periods = 2000;
experiment.ir_periods = 63;
experiment.plot_periods = 1:40;
experiment.band_probabilities = [0.25 0.75];
experiment.shock = struct('name','eps_x', ...
    'simulation_scale',exp(-0.034),'impulse_size',1);
experiment.explosion_policy = struct('magnitude_limit',1000, ...
    'reject_nonfinite',true,'variable_indices',1:13);
end
