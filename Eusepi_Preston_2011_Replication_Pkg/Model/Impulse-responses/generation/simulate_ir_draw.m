function imp_resp_draw = simulate_ir_draw(main_config, epsZ_full, idx)
%% SIMULATE_IR_DRAW Simulate one baseline and shocked impulse-response draw.

T_imp = main_config.impulse_horizon;
sim_L = main_config.training_sample_length;
T_tot = sim_L+T_imp;

opt_x1 = main_config.shock_scale;
x = main_config.model_param; %% parameters full model
% %  param(1) = 1;  %% IH
% %  param(2) = 0; %% External effects
% %  param(3) = 1.2; %% sigma
% %  param(4) = 0; %% simple RBC (Takes 1 or zero)
% %  param(5) = 0; %% constant gain

S_mat = [main_config.shock_scale];
fb = main_config.feedback;
lern = main_config.learning;
exp_gen = main_config.expectations_enabled;
imp_resp = main_config.impulse_response_enabled;

%% Simulate full sample
epsZ_imp1 = main_config.normalized_shock_size;

full = 1; %% set == 1 for full simulation (then initial regressors are at REE)

epsZ = epsZ_full;

ini1 = 0; ini2 = 0; ini3 = 0; ini4 = 0; ini5 = 0;

%% Simulate stationary model
% [Y_var,Exp_R_1Q,Exp_R_3Q,Exp_gy_1Q,Exp_gy_4Q,Exp_gn_1Q,Exp_gn_4Q,...
%               Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,invalid_simulation] = ...
%          Model_Simul_Sept_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L,epsZ);
%

[Y_var,Exp_R_1Q,Exp_R_3Q,Exp_w_1Q,Exp_w_2Q,Exp_w_3Q,...
    Exp_w_4Q,Exp_rk_1Q,Exp_rk_2Q,Exp_rk_3Q,Exp_rk_4Q,...
    Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,invalid_simulation] = ...
    simulate_model_paths(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L,epsZ);

expectations = pack_expectations(Exp_R_1Q, Exp_R_3Q, Exp_w_1Q, Exp_w_2Q, ...
    Exp_w_3Q, Exp_w_4Q, Exp_rk_1Q, Exp_rk_2Q, Exp_rk_3Q, Exp_rk_4Q);

%% NOTE: the imp-resp shock impacts at sim_L+2. (That is, the initial
%% state saved corresponds to observation sim_L_1.) Accordingly, the
%% impulse response has a lenght of T_imp-1, where the first observation
%% is the impact response of the shock. Thus, the growth rate is defined
%% as impact response (sim_L+2) less initial state (sim_L+1).
impresp1 = build_ir_series(Y_var, expectations, idx, sim_L+2:size(Y_var,2), sim_L+1:size(Y_var,2)-1);

%% Add 1 std shock...
full = 0;

ini1 = Regressors_ini;
ini2 = R_mat_ini;
ini3 = state_ini;
ini4 = OMEGA_c_ini;
ini5 = OMEGA_0_ini;

mat_imp = epsZ_full(T_tot-T_imp+1:end)+[1/opt_x1,zeros(1,T_imp-1)];

%% NOTE: this is to normalize the shock to 1 std
epsZ_imp1 = mat_imp;

%% Simulate stationary model
% [Y_var,Exp_R_1Q,Exp_R_3Q,Exp_gy_1Q,Exp_gy_4Q,Exp_gn_1Q,Exp_gn_4Q,...
%               Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,invalid_simulation] = ...
%          Model_Simul_Sept_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L,epsZ);

[Y_var,Exp_R_1Q,Exp_R_3Q,Exp_w_1Q,Exp_w_2Q,Exp_w_3Q,...
    Exp_w_4Q,Exp_rk_1Q,Exp_rk_2Q,Exp_rk_3Q,Exp_rk_4Q,...
    Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,invalid_simulation] = ...
    simulate_model_paths(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L,epsZ);

expectations = pack_expectations(Exp_R_1Q, Exp_R_3Q, Exp_w_1Q, Exp_w_2Q, ...
    Exp_w_3Q, Exp_w_4Q, Exp_rk_1Q, Exp_rk_2Q, Exp_rk_3Q, Exp_rk_4Q);

%% NOTE: the imp-resp shock impacts at sim_L+2
impresp2 = build_ir_series(Y_var, expectations, idx, 2:size(Y_var,2), 1:size(Y_var,2)-1);

imp_resp_draw = impresp2 - impresp1;

end

function expectations = pack_expectations(Exp_R_1Q, Exp_R_3Q, Exp_w_1Q, Exp_w_2Q, ...
    Exp_w_3Q, Exp_w_4Q, Exp_rk_1Q, Exp_rk_2Q, Exp_rk_3Q, Exp_rk_4Q)

expectations = struct();
expectations.Exp_R_1Q = Exp_R_1Q;
expectations.Exp_R_3Q = Exp_R_3Q;
expectations.Exp_w_1Q = Exp_w_1Q;
expectations.Exp_w_2Q = Exp_w_2Q;
expectations.Exp_w_3Q = Exp_w_3Q;
expectations.Exp_w_4Q = Exp_w_4Q;
expectations.Exp_rk_1Q = Exp_rk_1Q;
expectations.Exp_rk_2Q = Exp_rk_2Q;
expectations.Exp_rk_3Q = Exp_rk_3Q;
expectations.Exp_rk_4Q = Exp_rk_4Q;

end
