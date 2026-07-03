% run_model_simul_example.m
% Example parameterization for Model_Simul_Oct_2009.
% These are the standalone values that were previously commented in the
% simulation function.

pkg_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(pkg_dir, 'Common'), '-end');

%% Simulation parameters (general)
exp_gen = 1;
imp_resp = 0;
full = 1;

%% These parameters are not needed by this configuration.
epsZ_imp1 = 1;
ini1 = 0;
ini2 = 0;
ini3 = 0;
ini4 = 0;
ini5 = 0;
sim_L = 1;

opt_x = exp(-0.034);

% x(1): Infinite-horizon formulation flag
% x(2): External-effects parameter
% x(3): Utility-function parameter sigma
% x(4): Simple-RBC specification flag
% x(5): Inverse labor-supply elasticity
% x(6): Fixed gain learning
x = [1; 0; 1; 1; 0.01; 0.0049];

S_mat = opt_x';

fb = 1;
lern = 1;

epsZ = randn(1, 22000);

[Y_var, Exp_R_1Q, Exp_R_3Q, Exp_w_1Q, Exp_w_2Q, Exp_w_3Q, ...
    Exp_w_4Q, Exp_rk_1Q, Exp_rk_2Q, Exp_rk_3Q, Exp_rk_4Q, ...
    Regressors_ini, R_mat_ini, state_ini, OMEGA_c_ini, OMEGA_0_ini, ...
    invalid_simulation] = ...
    Model_Simul_Oct_2009(x, S_mat, fb, lern, exp_gen, imp_resp, full, ...
    epsZ_imp1, ini1, ini2, ini3, ini4, ini5, sim_L, epsZ);
