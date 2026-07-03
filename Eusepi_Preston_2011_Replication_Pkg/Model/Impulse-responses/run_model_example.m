% run_model_example.m
% Example parameterization for Model_Sept_2009.
% These are the parameters E&P initially had in model file, commented out.

param = zeros(6, 1);

param(1) = 1;       % Infinite-horizon formulation
param(2) = 0;       % No external effects
param(3) = 1;       % Utility-function parameter, sigma
param(4) = 1;       % Simple RBC specification — should be 1 or 0
param(5) = 0.0001;  % Inverse labor-supply elasticity
param(6) = 0;       % Participation specification; currently unused

[A, C, invA0, k_y, disc, ct1] = Model_Sept_2009(param);