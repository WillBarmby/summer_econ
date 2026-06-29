

%clear all

function [Moments_level_detr,Moments_growth,Auto_corr_growth,...
    Output_growth_auto,corr_w1,corr_w2,corr_w3,corr_w4,...
    corr_rk1,corr_rk2,corr_rk3,corr_rk4,corr_R1,corr_R3,...
    acorr_w1,acorr_w2,acorr_w3,acorr_w4,...
    acorr_rk1,acorr_rk2,acorr_rk3,acorr_rk4,acorr_R1,acorr_R3,...
    STD_var_wrk,w_auto,rk_auto] = bus_cycle_stats_fun(not)
 


 global epsZ 

%% Model and simulation parameters 

opt_x = exp(0.144);
 
opt_x1 = opt_x;

  x = [1;0;1;1;0.0001;0.0027]; %% parameters full model
 % %  param(1) = 1;  %% IH
% %  param(2) = 0; %% External effects
% %  param(3) = 1.2; %% sigma
% %  param(4) = 0; %% simple RBC (Takes 1 or zero)
% %  param(5) = 0.01; %% frish labor supply elasticity
% %  param(6) = 0; %% constant gain
 
 S_mat = [opt_x];  


fb = 1;
lern = 1;


exp_gen = 1;

imp_resp = 0;

full = 1;

 % NOT USED
 
 
 epsZ_imp1 = 0; ini1 = 0; ini2 = 0; ini3 = 0;ini4 = 0;ini5 = 0; sim_L = 0;


 % Simulation parameters
 
 n_disc = 5000; % initial observations discarded
 
%   Sim_length = 5165;
% 
%    epsZ = randn(1,Sim_length);


 
 

%% Transforming nonstationary variables


%% endogenous variables

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





 
 %%% Compute SS for initial conditions
 
 %% from the model file:   

  
  
 %% parameters
 
delta = 0.025; %% depreciation rate

alpha = 0.34; %% capital share

gamma = exp(0.0053); %% mean of gdp growth in current data 

sigma = x(3);

eps_H = x(5);

delta_tilda = 1-(1-delta)/gamma; %% investment to capital ratio
 
beta = 0.99*gamma^(sigma-1); %% adjusted discount rate (not really used...)
  
 %% steady state
 
  beta_tilda = beta*gamma^(1-sigma); %% modified discount rate
 
  theta = (gamma*beta_tilda^(-1)-(1-delta))/delta;

  yk_ratio = delta*theta/(alpha*gamma);

  ik_ratio = delta_tilda;

  ck_ratio = yk_ratio-ik_ratio;

  cy_ratio = ck_ratio/yk_ratio;
 
  delta_s = (1-delta)/gamma;

  R_tilda = beta_tilda^(-1)-delta_s;

  psi = cy_ratio^(-1)*(1-alpha); 
 
  iy_ratio = yk_ratio/ik_ratio;

  phiH = eps_H-(sigma-1)/sigma*psi;
 
  
  %% Initial conditions
  
  ln_Y0 = 0; %% normalization of X0 such that y_bar/X0 = 1
  
  ln_C0 = log(psi*(1-alpha));
  
  ln_I0 = log(1-exp(ln_C0));
  
  ln_W0 = log(psi)+ln_C0-log(0.3); %% set initial ss hours at 0.3
 

  

  % Simulated series (nonstationary variables expressed in efficiency units)

  %tic
  
% [Y_var,Exp_R_1Q,Exp_R_3Q,Exp_w_1Q,Exp_w_4Q,Exp_rk_1Q,Exp_rk_4Q,...
%               Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
%          Model_Simul_Sept_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);


[Y_var,Exp_R_1Q,Exp_R_3Q,Exp_w_1Q,Exp_w_2Q,Exp_w_3Q,...
         Exp_w_4Q,Exp_rk_1Q,Exp_rk_2Q,Exp_rk_3Q,Exp_rk_4Q,...
              Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
         Model_Simul_Oct_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);


 

y_growth_vec = [Y_var(wage,2:end);Y_var(cons,2:end);Y_var(invst,2:end);Y_var(output,2:end)]-...
                 [Y_var(wage,1:end-1);Y_var(cons,1:end-1);Y_var(invst,1:end-1);Y_var(output,1:end-1)]+...
                      ones(4,1)*Y_var(gamma_x,2:end); %% NOTE: shorter by one observation

% Levels 
% NOTE: the growth and level series have the same timing (I mean, they both start at
% time 1)

y_level_vec = zeros(size(y_growth_vec,1),size(y_growth_vec,2));


y_level_vec(:,1) = y_growth_vec(:,1)+100*log(gamma)+[ln_W0;ln_C0;ln_I0;ln_Y0];  
 

 
 for j = 2:size(y_growth_vec,2)
 
 y_level_vec(:,j) = y_growth_vec(:,j)+100*log(gamma)+y_level_vec(:,j-1);
     
 end

 
 
 % Set simulated data in levels and growth rates (include stationary
 % variables)
 
 % LIST of VARS: {'w','c','i','y','b','h'}
 c_i = 2; i_i = 3; y_i = 4; w_i = 1; b_i = 5; h_i = 6;

 
 var_level = [y_level_vec;Y_var(bond,2:end);Y_var(hours,2:end)];
 
 
 
 var_growth = 4*[y_growth_vec;Y_var(bond,2:end);...
              Y_var(hours,2:end)-Y_var(hours,1:end-1)];
              %% NOTE: of course the riskless return is not exp. in growth
              %% rates!
 
              
 %% Forecast Errors
      
     
        % Real rate
        
        Real_rate_error_Q1 = Y_var(bond,3:end) - Exp_R_1Q(2:end-1);

        Real_rate_error_Q3 = Y_var(bond,5:end) - Exp_R_3Q(2:end-3);

        
        % Wage
        
        wage_error_Q1 = Y_var(wage,3:end) - Exp_w_1Q(2:end-1);
        
        wage_error_Q2 = Y_var(wage,4:end) - Exp_w_2Q(2:end-2);
        
        wage_error_Q3 = Y_var(wage,5:end) - Exp_w_3Q(2:end-3);
        
        wage_error_Q4 = Y_var(wage,6:end) - Exp_w_4Q(2:end-4);

        
        % Return to capital
        
        rk_error_Q1 = Y_var(rk,3:end) - Exp_rk_1Q(2:end-1);
        
        rk_error_Q2 = Y_var(rk,4:end) - Exp_rk_2Q(2:end-2);
        
        rk_error_Q3 = Y_var(rk,5:end) - Exp_rk_3Q(2:end-3);
        
        rk_error_Q4 = Y_var(rk,6:end) - Exp_rk_4Q(2:end-4);
        
        
        
      %% Discard initial observations 
 
 var_level = var_level(:,n_disc:end);
 
 var_growth = var_growth(:,n_disc:end);
              
  Y_var = Y_var(:,n_disc:end);
 
 
 Real_rate_error_Q1 = Real_rate_error_Q1(:,n_disc:end);
 
 Real_rate_error_Q3 = Real_rate_error_Q3(:,n_disc:end);
 
 
 wage_error_Q1 = wage_error_Q1(:,n_disc:end); 
 
 wage_error_Q2 = wage_error_Q2(:,n_disc:end); 

 wage_error_Q3 = wage_error_Q3(:,n_disc:end); 

 wage_error_Q4 = wage_error_Q4(:,n_disc:end); 

 
 rk_error_Q1 = rk_error_Q1(:,n_disc:end); 

 rk_error_Q2 = rk_error_Q2(:,n_disc:end); 

 rk_error_Q3 = rk_error_Q3(:,n_disc:end); 

 rk_error_Q4 = rk_error_Q4(:,n_disc:end); 

 
 
 % MSE
 
%  MSE_y_Q1 = sum(Income_error_Q1.^2)/length(Income_error_Q1);
%  
%  
%  % RMSE
%  
%  RMSE_y_Q1 = sqrt(sum(Income_error_Q1.^2)/length(Income_error_Q1));
%  
 
 
 
 % Compute HP filter
 
 %% Compute hp filtered series


hp_data_sample = var_level';
 
[y_sample_trend,desvabs] = hpfilter(hp_data_sample,1600);

var_level_detr = hp_data_sample'-y_sample_trend';


 
  
  
%% Compute bc statistics

  % Levels 
  
  STD_var_level_detr = std(var_level_detr,0,2);
  

rowMat = 1:size(var_level_detr,1);

maxT = 10;


[auto cross] = autoCrossCorrel(var_level_detr, rowMat, maxT, {'w','c','i','y','b','h'}); 


Moments_level_detr = [STD_var_level_detr(y_i)
                     STD_var_level_detr(c_i)/STD_var_level_detr(y_i)
                     STD_var_level_detr(i_i)/STD_var_level_detr(y_i)
                     STD_var_level_detr(h_i)/STD_var_level_detr(y_i)
                     STD_var_level_detr(w_i)/STD_var_level_detr(y_i)
                     STD_var_level_detr(b_i)/STD_var_level_detr(y_i)
                     cross{1+y_i,1+c_i}
                     cross{1+y_i,1+i_i}
                     cross{1+y_i,1+h_i}
                     cross{1+y_i,1+w_i}
                     cross{1+y_i,1+b_i}
                     cross{1+h_i,1+w_i}];
                 
   % Growth rates
   
    STD_var_growth = std(var_growth,0,2);
  

rowMat = 1:size(var_growth,1);

maxT = 10;


[auto cross] = autoCrossCorrel(var_growth, rowMat, maxT, {'w','c','i','y','b','h'}); 


Moments_growth = [   STD_var_growth(y_i)
                     STD_var_growth(c_i)/STD_var_growth(y_i)
                     STD_var_growth(i_i)/STD_var_growth(y_i)
                     STD_var_growth(h_i)/STD_var_growth(y_i)
                     STD_var_growth(w_i)/STD_var_growth(y_i)
                     STD_var_growth(b_i)/STD_var_growth(y_i)
                     cross{1+y_i,1+c_i}
                     cross{1+y_i,1+i_i}
                     cross{1+y_i,1+h_i}
                     cross{1+y_i,1+w_i}
                     cross{1+y_i,1+b_i}
                     cross{1+h_i,1+w_i}];
                     
 Auto_corr_growth = [ auto{2,1+c_i},
                          auto{2,1+i_i},
                          auto{2,1+h_i},
                          auto{2,1+w_i},
                          auto{2,1+y_i},
                          auto{2,7}];      
                      
     
     Output_growth_auto = [auto{2,1+y_i},
                            auto{3,1+y_i},
                            auto{4,1+y_i}
                            auto{5,1+y_i}
                            auto{6,1+y_i}
                            auto{7,1+y_i}
                            auto{8,1+y_i}
                            auto{9,1+y_i}
                            auto{10,1+y_i}];
                        

                            
  %% Compute statistics for w (eff. units) and rk 
  
  
  
  %% Compute bc statistics

  % Levels 
  
  var_wrk = [Y_var(wage,:);Y_var(rk,:)];
  
  STD_var_wrk = std(var_wrk,0,2);
  

rowMat = 1:size(var_wrk,1);

maxT = 10;


[auto cross] = autoCrossCorrel(var_wrk, rowMat, maxT, {'w','rk'});

w_auto = [auto{2,1+1},
                            auto{3,1+1},
                            auto{4,1+1}
                            auto{5,1+1}
                            auto{6,1+1}
                            auto{7,1+1}
                            auto{8,1+1}
                            auto{9,1+1}
                            auto{10,1+1}];
                        
rk_auto = [auto{2,1+1},
                            auto{3,1+2},
                            auto{4,1+2}
                            auto{5,1+2}
                            auto{6,1+2}
                            auto{7,1+2}
                            auto{8,1+2}
                            auto{9,1+2}
                            auto{10,1+2}];

  
  
  
corr_w1 = corr(var_growth(y_i,1:end-1)',wage_error_Q1');

corr_w2 = corr(var_growth(y_i,1:end-2)',wage_error_Q2');

corr_w3 = corr(var_growth(y_i,1:end-3)',wage_error_Q3');

corr_w4 = corr(var_growth(y_i,1:end-4)',wage_error_Q4');


corr_rk1 = corr(var_growth(y_i,1:end-1)',rk_error_Q1');

corr_rk2 = corr(var_growth(y_i,1:end-2)',rk_error_Q2');

corr_rk3 = corr(var_growth(y_i,1:end-3)',rk_error_Q3');

corr_rk4 = corr(var_growth(y_i,1:end-4)',rk_error_Q4');


corr_R1 = corr(var_growth(y_i,1:end-1)',Real_rate_error_Q1');

corr_R3 = corr(var_growth(y_i,1:end-3)',Real_rate_error_Q3');

                     
acorr_w1 = corr(wage_error_Q1(2:end)',wage_error_Q1(1:end-1)');

acorr_w2 = corr(wage_error_Q2(3:end)',wage_error_Q2(1:end-2)');

acorr_w3 = corr(wage_error_Q3(4:end)',wage_error_Q3(1:end-3)');

acorr_w4 = corr(wage_error_Q4(5:end)',wage_error_Q4(1:end-4)');


acorr_rk1 = corr(rk_error_Q1(2:end)',rk_error_Q1(1:end-1)');

acorr_rk2 = corr(rk_error_Q2(3:end)',rk_error_Q2(1:end-2)');

acorr_rk3 = corr(rk_error_Q3(4:end)',rk_error_Q3(1:end-3)');

acorr_rk4 = corr(rk_error_Q4(5:end)',rk_error_Q4(1:end-4)');


acorr_R1 = corr(Real_rate_error_Q1(2:end)',Real_rate_error_Q1(1:end-1)');

acorr_R3 = corr(Real_rate_error_Q3(4:end)',Real_rate_error_Q3(1:end-3)');

                     
                 
  