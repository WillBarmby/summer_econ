

if exist('skip_clear','var') ~= 1
clear all;%clc
end
%%% MAIN FILE FOR GENERATIONG IMPULSE RESPONSES


%% The file generates 1000 impulse responses, depending on the initial
%% state of the economy

global epsZ 


T_imp = 64; %% T_imp-1 is the number of periods in the IR

sim_L = 2000; %% this denotes the total number of observations that have 
              %% to be discarded before generating the IR

T_tot = sim_L+T_imp; %% total length of simulation


n_draws = 100; %% number of IR simulated

%% select percentile
band_up = 1;.15*n_draws;

band_down = 1;(1-0.15)*n_draws;

%% OPTIONS

if exist('imp_resp_store','var') ~= 1
imp_resp_store = 1;
end

store_c  = imp_resp_store; %% set == 1 to store matrix of impulse responses


%% Define model parameters ans select options in the simulation files


opt_x = exp(-0.034);
 
opt_x1 = opt_x;

  x = [1;0;1;1;0.0001;0.002]; %% parameters full model
 % %  param(1) = 1;  %% IH
% %  param(2) = 0; %% External effects
% %  param(3) = 1.2; %% sigma
% %  param(4) = 0; %% simple RBC (Takes 1 or zero)
% %  param(5) = 0; %% constant gain
 
 S_mat = [opt_x];  


fb = 1;

if exist('imp_resp_learning','var') ~= 1
imp_resp_learning = 1;
end

lern = imp_resp_learning;


exp_gen = 1;

imp_resp = 1;





%% Define the IR matrices

n_impulse_resp = 14; %% number of impulse responses that you want to plot. 
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

%% Simulate full sample

epsZ_imp1 = 1;


full = 1; %% set == 1 for full simulation (then initial regressors are at REE)

epsZ = epsZ_full;

ini1 = 0; ini2 = 0; ini3 = 0; ini4 = 0; ini5 = 0;



 %% Model parameters that we need
 % vars location (needed below) 
 % jump

% jump

rk = 1;
wage = 2;
output = 4;
hours = 5;
cons = 12;
invst = 9;
mp = 8; %% externality
caput = 6;
rk_sum = 10; %% capital income
w_sum = 11; %% labor income
bond = 3;

% state
cap = 7;

%% exogenous variables
gamma_x = 13;



 %% Simulate stationary model
 
% [Y_var,Exp_R_1Q,Exp_R_3Q,Exp_gy_1Q,Exp_gy_4Q,Exp_gn_1Q,Exp_gn_4Q,...
%               Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
%          Model_Simul_Sept_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);
% 

[Y_var,Exp_R_1Q,Exp_R_3Q,Exp_w_1Q,Exp_w_2Q,Exp_w_3Q,...
         Exp_w_4Q,Exp_rk_1Q,Exp_rk_2Q,Exp_rk_3Q,Exp_rk_4Q,...
              Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
         Model_Simul_Oct_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);


 %% Compute deviation from BGP        
         
 y_growth_vec = [Y_var(wage,sim_L+2:end);Y_var(cons,sim_L+2:end);Y_var(invst,sim_L+2:end);Y_var(output,sim_L+2:end)]-...
                     [Y_var(wage,sim_L+1:end-1);Y_var(cons,sim_L+1:end-1);Y_var(invst,sim_L+1:end-1);Y_var(output,sim_L+1:end-1)]+...
                      ones(4,1)*Y_var(gamma_x,sim_L+2:end);
                  
                 
                  
  %% NOTE: the imp-resp shock impacts at sim_L+2. (That is, the initial
  %% state saved corresponds to observation sim_L_1.) Accordingly, the
  %% impulse response has a lenght of T_imp-1, where the first observation
  %% is the impact response of the shock. Thus, the growth rate is defined
  %% as impact response (sim_L+2) less initial state (sim_L+1).
                      
                      
y_detr_vec = zeros(size(y_growth_vec,1),size(y_growth_vec,2));


y_detr_vec(:,1) = y_growth_vec(:,1);  
 
 %% NOTE: the initial observation corresponds to the initial growth rate.

 
 for j = 2:size(y_growth_vec,2)
 
 y_detr_vec(:,j) = y_growth_vec(:,j)+y_detr_vec(:,j-1);
     
 end

 

 %% Compute impresp1
 
 % LIST of VARS: {'w','c','i','y','b','h','rk','we','Exprk1','Expw1','Exprk20','Exprk40','Expwe20','Expwe40'}
 
 impresp1 = [y_detr_vec;Y_var(bond,sim_L+2:end);Y_var(hours,sim_L+2:end);...
             Y_var(rk,sim_L+2:end);Y_var(wage,sim_L+2:end);...
             Exp_rk_1Q(sim_L+2:end);Exp_w_1Q(sim_L+2:end);...
             Exp_rk_3Q(sim_L+2:end);Exp_rk_4Q(sim_L+2:end);...
             Exp_w_3Q(sim_L+2:end);Exp_w_4Q(sim_L+2:end);];
 
 
 
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
%               Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
%          Model_Simul_Sept_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);

 
[Y_var,Exp_R_1Q,Exp_R_3Q,Exp_w_1Q,Exp_w_2Q,Exp_w_3Q,...
         Exp_w_4Q,Exp_rk_1Q,Exp_rk_2Q,Exp_rk_3Q,Exp_rk_4Q,...
              Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
         Model_Simul_Oct_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);     
     
     
 %% Compute deviation from BGP        
         
 y_growth_vec = [Y_var(wage,2:end);Y_var(cons,2:end);Y_var(invst,2:end);Y_var(output,2:end)]-...
                     [Y_var(wage,1:end-1);Y_var(cons,1:end-1);Y_var(invst,1:end-1);Y_var(output,1:end-1)]+...
                      ones(4,1)*Y_var(gamma_x,2:end); 
                  
                 
                %% NOTE: the imp-resp shock impacts at sim_L+2
                      
                      
y_detr_vec = zeros(size(y_growth_vec,1),size(y_growth_vec,2));


y_detr_vec(:,1) = y_growth_vec(:,1);  
 

 
 for j = 2:size(y_growth_vec,2)
 
 y_detr_vec(:,j) = y_growth_vec(:,j)+y_detr_vec(:,j-1);
     
 end

 
  % LIST of VARS: {'w','c','i','y','b','h','rk','we','Exprk1','Expw1','Exprk20','Exprk40','Expwe20','Expwe40'}

 impresp2 = [y_detr_vec;Y_var(bond,2:end);Y_var(hours,2:end);...
             Y_var(rk,2:end);Y_var(wage,2:end);...
             Exp_rk_1Q(2:end);Exp_w_1Q(2:end);...
             Exp_rk_3Q(2:end);Exp_rk_4Q(2:end);...
             Exp_w_3Q(2:end);Exp_w_4Q(2:end);];
 
 
         
 


for j = 1:n_impulse_resp
    
imp_resp_vec{j}(ctn,:) = impresp2(j,:)-impresp1(j,:);

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

    if exist('imp_resp_output_file','var') ~= 1
    imp_resp_output_file = 'COEFF_STORE_impresp_mat_learn_bench2.mat';
    end

    if exist('imp_resp_output_var','var') ~= 1
    imp_resp_output_var = 'imp_resp_vec_RBC_learn_bench2';
    end

    main_dir = fileparts(mfilename('fullpath'));

    imp_resp_output.(imp_resp_output_var) = imp_resp_vec;

    save(fullfile(main_dir, imp_resp_output_file), '-struct', 'imp_resp_output');
end    
