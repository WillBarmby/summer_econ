




function Obj = Obj_fun_Sept_2009(opt)




 global epsZ

%% Model and simulation parameters 

opt_x = exp(opt);
 

  x = [1;0;1;1;0.0001;0.002]; %% parameters full model
 % %  param(1) = 1;  %% IH
% %  param(2) = 0; %% External effects
% %  param(3) = 1.2; %% sigma
% %  param(4) = 0; %% simple RBC (Takes 1 or zero)
% %  param(5) = 0.01; %% frish labor supply elasticity
% %  param(6) = 0; %% constant gain
 
 S_mat = [opt_x];  


fb = 1;
lern = 1;


exp_gen = 0;

imp_resp = 0;

full = 1;

 % NOT USED
 
 
 epsZ_imp1 = 0; ini1 = 0; ini2 = 0; ini3 = 0;ini4 = 0;ini5 = 0; sim_L = 0;


 % Simulation parameters
 
 n_disc = 2000; % initial observations discarded
 
%  Sim_length = 52000;
%  
%  epsZ = randn(1,Sim_length);


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

  
[Y_var,Exp_R_1Q,Exp_R_3Q,Exp_gy_1Q,Exp_gy_4Q,Exp_gn_1Q,Exp_gn_4Q,...
              Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
         Model_Simul_Sept_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);




if ct2 == 0

% Growth rates (de-meaned)

 

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
 
 
%   var_growth = [y_growth_vec;Y_var(bond,2:end);...
%               Y_var(hours,2:end)-Y_var(hours,1:end-1)];
%               %% NOTE: of course the riskless return is not exp. in growth
%               %% rates!

 
 
              
 %% Forecast Errors
      
     
        
        % Income/GDP
        
% Income_error_Q1 = var_growth(y_i,2:end) - Exp_gy_1Q(2:end-1);
        
        
        
     
        
%% Discard initial observations 
 
 var_level = var_level(:,n_disc:end);
 
              
%  Y_var = Y_var(:,n_disc:end);
%  
%  
%  Income_error_Q1 = Income_error_Q1(:,n_disc:end); 
 
 
 
 % Compute HP filter
 
 %% Compute hp filtered series


hp_data_sample = var_level';
 
[y_sample_trend,desvabs] = hpfilter(hp_data_sample,1600);

var_level_detr = hp_data_sample'-y_sample_trend';


 
  
  
%% Compute bc statistics

  % Levels 
  
  STD_var_level_detr = std(var_level_detr,0,2);
  




%% Objective function

     
     
%      auto_income_1Q = corr(Income_error_Q1(2:end)',Income_error_Q1(1:end-1)');
     STD_var_level_detr(y_i)
   
     Obj = (STD_var_level_detr(y_i)-1.51)^2;
     
  
else
    
    
    Obj = 1000000000000000000000000000;
    
    
end