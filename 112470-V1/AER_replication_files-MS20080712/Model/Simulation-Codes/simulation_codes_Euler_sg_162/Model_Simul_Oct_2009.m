 


 %%% THIS FUNCTION SIMULATES A MODEL (defined by Model function) GIVEN THE
 %%% SET OF PARAMETERS DEFINED IN x 

 
  
  


     function [Y_var,Exp_R_1Q,Exp_R_3Q,Exp_w_1Q,Exp_w_2Q,Exp_w_3Q,...
         Exp_w_4Q,Exp_rk_1Q,Exp_rk_2Q,Exp_rk_3Q,Exp_rk_4Q,...
              Regressors_ini,R_mat_ini,state_ini,OMEGA_c_ini,OMEGA_0_ini,ct2] = ...
         Model_Oct_Sept_2009(x,S_mat,fb,lern,exp_gen,imp_resp,full,epsZ_imp1,ini1,ini2,ini3,ini4,ini5,sim_L);

    global epsZ


  
    
    
%% COMMENT BELOW IF USING AS A FUNCTION!

%    clear all
%   %clc
%   
% %% Simulation parameters (general)
%  exp_gen = 1;
%  
%  imp_resp = 0; 
%  
%  full = 1;
%  
%  
%  
%  
%  %% the parameters below are not needed (they are assigned arbitrary values)
%  epsZ_imp1 = 1;
%  
%  ini1 = 0; ini2 = 0; ini3 = 0; ini4 = 0; 
%  
%  sim_L = 1;
% 
% 
% opt_x = exp(-0.034);
% 
% %  param(1) = 1;  %% IH
% %  param(2) = 0; %% External effects
% %  param(3) = 1.2; %% sigma
% %  param(4) = 0; %% simple RBC (Takes 1 or zero)
% % param(5) = 0.01; %% frish labor supply elasticity
% %  param(6) = 0; %% 0 for standard nonsep, 1 for partic. model
%  
%   x = [1;0;1;1;0.01;0.0049]; %% parameters full model
%   
%  S_mat = [(opt_x)]';  
%  
%  fb = 1;
%  
%  lern = 1;
%  
%  
% 
%   
% epsZ = randn(1,22000);
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 

 gs = 0;
 
 
 
% Control on bounds for calibrated coefficients
 ct2 = 0; 
  
 
 
%%%%%%%%%%%%%%%%%%%%%--- OPTIONS ---%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


gen_shocks = gs; %% set to 1 to generate new sequence of shocks

learning = lern;  %% set == 0 for simulation under REE (no learning update)

feedback = fb;  %% set == 0 for NO feedbacks (active if learning ==1)
               %% NOTE: this gives the option of simulating the model under 
               %% REE while estimating the PLM recursively.

cg = 1;        %% set == 1 if constant gain (active if learning ==1)

sga = 0;       %% set == 1 is stochastig gradient (active if learning ==1)

n_c = 1;       %% set == 1 if want to include the constant in the agent's 
               %% regression.

p_f = 0;       %% set == 1 to activate projection facility
               %% NOTE: also computes the beliefs' distribution in the case 
               %% of no-feedbacks from learning
               %% (active if learning ==1)   

pf_k = 8;   %% defines how tight is the projection facility               
               %% (active if learning ==1)
               
store = 0;   %% set == 1 to store the coefficients (active if learning==1)


s_length = 55000; %% length of the simulation (active if gen_shocks ==1)

ini_gain = 500; %% initial gain for RLS (active if learning==1)

g_gain = x(6); %% fixed gain learning (active if learning==1)

R_mat_tol = 1.0856345e-010; %% if RCOND of inv(R) is above R_mat_tol,
                            %% the learning algorithm switches to SG
                            %% (active if learning==1)

ini_cds = 0;   %% set == 1 if initial conditions for calculating REE are 
               %% already defined
                               
bigT_vec = [1 2 3 4];   %% vector containing the expectations horizons (active if exp_gen == 1 )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Store/impulse resp. and forecast options

if imp_resp == 1
    
    store = 0;
    
else
    
    Regressors_ini = 0;  R_mat_ini = 0; state_ini = 0;
    OMEGA_c_ini = 0;OMEGA_0_ini = 0;

end

if exp_gen == 0
    
Exp_Y_var = 0;
Exp_R_1Q = 0;Exp_R_3Q = 0; Exp_w_1Q = 0;
Exp_w_2Q = 0;Exp_w_3Q = 0;Exp_w_4Q = 0; 
Exp_rk_1Q = 0; Exp_rk_2Q = 0;Exp_rk_3Q = 0;Exp_rk_4Q = 0;

end


%% %%%%%%%%%%%%
%% [1] MODEL %%
%% %%%%%%%%%%%%
 %% Call the model to simulate (the model needs to be in the form described
 %% in the Documentation fle: ALM_documentation.tex


[A,C,invA0,k_y,disc,ct1] = Model_Sept_2009(x);

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


  

ct2 = ct1;

if g_gain < 0 | g_gain > 0.075
     
     ct2 = 1;
     
end
 
if ct2 == 0


 %% ATTENTION!: Regression equations/coefficients
 %% NOTE1: these should be consistent with the model used in the Model
 %% function
 %% NOTE2: regressors must be in the last raws
 %% NOTE3: equations to estimate must be the the first raws


n_x = 1;  % regressors, excluding the constant

n_eq = 7; % number of equations to estimate


n_var = size(A{1},1); % total variables in the model

n_shocks = size(C,2); % n of shocks in the model


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% [2] GENERATE i.i.d SHOCKS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if gen_shocks == 1
    
RND_Mat = randn(n_shocks,s_length);

save SHOKS_mat RND_Mat

else
    
%% comment if use this file as a function    
 % load SHOKS_mat;

 if full == 1

%% If use this file as function
RND_Mat = epsZ;

 else 

RND_Mat = epsZ_imp1;

end

end  %% ends gen_shock loop

%% Checking dimensions of the shock matrix

if size(RND_Mat,1) ~= n_shocks
    
    disp('wrong number of simulated shocks!')
    
    return
    
end





%% Shocks variances

var_model = diag(S_mat.^2);


%% Shocks

Shocks = diag(S_mat)*RND_Mat;





%% %%%%%%%%%%%%%%%%%%%%%%%%%
%% [3] SET-UP REGRESSORS  %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%

 %% Checking consistency with the model

if n_x > n_var
    
    disp('too many regressors!')
    
    return
    
end

if n_eq > n_var
    
    disp('too many equations to estimate!')
    
    return
    
end

 %% Regression coefficients

for ctn = 1:n_eq
    
    Regressors{ctn} = zeros(n_x+n_c,1);
    
    Regressors1{ctn} = zeros(n_x+n_c,1);
    
    Regressors_RE{ctn} = zeros(n_x+n_c,1);
end


%% Define OMEGA_0 and OMEGA_c

OMEGA_0 = zeros(n_var,1);

OMEGA_c = zeros(n_var,n_var);


%% Define R(t) and X_vec Regressors vectors

R_mat = eye(n_c+n_x);

X_vec = zeros(n_c+n_x,1);




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% [4] INITIAL CONDITIONS    %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%


 %% Solve the model under RE

if ini_cds == 0
    

ini_cond_0 = zeros(n_var,1);

ini_cond = zeros(n_var,n_var);

end





%% Solve with REDS-SOLDS


 [OMEGA_0_RE OMEGA_c_RE ct1] = REDS_SOLDS_Model_Sept_2009(x);
 

%% Solve with T-map iteration (double check solution!, other variables)

ini_cond_0 = OMEGA_0_RE;

ini_cond = OMEGA_c_RE;


 [OMEGA_0_RE OMEGA_c_RE] = REE_solve(ini_cond_0,ini_cond,A,C,invA0,k_y,disc);



[T_0_RE T_L_RE T_s_RE T_c_RE T_Ls_RE] = ...
   ALM_fun(A,C,invA0,OMEGA_0_RE,OMEGA_c_RE,k_y,disc);


%% Check E-Stability

% [eig_vec_0,eig_vec_c] = Estab_fun(A,C,invA0,OMEGA_0_RE,OMEGA_c_RE,T_c_RE,T_Ls_RE,k_y,disc); 


% %% updates initial condition for next time...NOT USED IN THIS VERSION
% 
% ini_cond = OMEGA_c_RE;
% 
% ini_cond_0 = OMEGA_0_RE;

if full == 1

%% Initial PLM

OMEGA_c = OMEGA_c_RE;


OMEGA_0 = OMEGA_0_RE;





%% Calculates the VCV matrix to initialize R(t), if want to use RLS
 %% Note: the matrix ini_VCV is square and of size n_var


if learning == 1
    
   
        
ini_VCV = VCV_Model(T_L_RE,T_s_RE,var_model);




 %% here we pick the regressors. In this case, capital:
 
R_mat(n_c+1:end,n_c+1:end) = ini_VCV(cap,cap);

 

   
end %% ends learning vcv loop



end %% end full==1 loop


%% WARNING! Initial conditions for regression coefficients
 %% NOTE: here I use the assumption that the constant is zero in REE. That
 %% could be changed by adding one line of code.


%% Set initial beliefs

for ctn = 1:n_eq
    
    
    Regressors_RE{ctn}(n_c+1:end) = Regressors{ctn}(n_c+1:end);
    
    if full == 1
    
      Regressors{ctn}(n_c+1:end) = OMEGA_c(ctn,cap);  
      
    else
    
      Regressors{ctn}(n_c+1:end) = ini1{ctn}(n_c+1:end);
        
    end
    
end
    
if full == 0 %% THIS IS USED WHEN PLOTTING IMPULSE RESPONSES


%% 1. Initial intercept is not zero! 
    
if n_c == 1
    
    for ctn = 1:n_eq
    
    Regressors{ctn}(1) = ini1{ctn}(1);
 
    end
 
end 


%% 2. initial second-moments matrix
 
 
 R_mat = ini2;
 

%% 3. initial OMEGA_0 and OMEGA_c

 if n_c == 1
    


OMEGA_0 = ini5;

 end %% end n_c loop


if n_x > 0

  
 
 OMEGA_c(:,cap) = ini4;

end

end %% closes the full==0 loop
 


%% Store the evolution of estimation coefficients


if store == 1

      for ctn = 1:n_eq
        
COEFF_STORE{ctn} = zeros(n_c+n_x,size(RND_Mat,2));   

      end

end



%% constant in X_vec

if n_c == 1
    
    X_vec(1) = 1;  
    
end


%% Initial condition for the vector of the variables

Y_var = zeros(n_var,size(RND_Mat,2));

%%NOTE: simulation starts at steady state

%% ...unless full == 0...

if full == 0
    
 Y_var(:,1) = ini3;
 
end



if exp_gen == 1

    
%% AGENTS' FORECATS: select the number of variable (< than n_var) to forecast

Exp_R_1Q = zeros(1,size(RND_Mat,2));

Exp_R_3Q = zeros(1,size(RND_Mat,2));

Exp_w_1Q = zeros(1,size(RND_Mat,2));

Exp_w_2Q = zeros(1,size(RND_Mat,2));

Exp_w_3Q = zeros(1,size(RND_Mat,2));

Exp_w_4Q = zeros(1,size(RND_Mat,2));

Exp_rk_1Q = zeros(1,size(RND_Mat,2));

Exp_rk_2Q = zeros(1,size(RND_Mat,2));

Exp_rk_3Q = zeros(1,size(RND_Mat,2));

Exp_rk_4Q = zeros(1,size(RND_Mat,2));



for ctn_e = 1:length(bigT_vec)
    
Exp_Y_var{ctn_e} = zeros(n_var,size(RND_Mat,2));


end



end %% close exp_gen loop


% %% Projection facility: NOT USED FOR NOW...
% 
% %% Get std from estimation without feedback
% 
% if p_f == 1
% 
%     [f_vec,x_vec,f_n_vec,mu_vec,sigma_vec] = Model_Simul_no_feedback(g_gain);
% 
% end 


%% %%%%%%%%%%%%%%%%%%%%%%%
%% [5] MODEL SIMULATION %%
%% %%%%%%%%%%%%%%%%%%%%%%%



for ctn_s = 2:size(RND_Mat,2)
    
    
%% uncomment if want to display the counter
% ctn_s


%% SIMULATE ALM

if learning == 1

    [T_0 T_L T_s T_c T_Ls] = ALM_fun(A,C,invA0,OMEGA_0,OMEGA_c,k_y,disc);

    
    Y_var(:,ctn_s) = T_0+T_L*Y_var(:,ctn_s-1)+T_s*Shocks(:,ctn_s-1);

    
else
    
    Y_var(:,ctn_s) = T_0_RE+T_L_RE*Y_var(:,ctn_s-1)+T_s_RE*Shocks(:,ctn_s-1);

end



%% checking for exploding series

if max(Y_var(:,ctn_s)) > 1000
 
   disp('exploding series')

   ct2 = 1; Y_var = 0; Exp_Y_var = 0;
            Regressors_ini = 0; R_mat_ini = 0;
            state_ini = 0; OMEGA_c_ini = 0; OMEGA_0_ini = 0;
           Exp_R_1Q = 0;Exp_R_3Q = 0; Exp_w_1Q = 0;
Exp_w_2Q = 0;Exp_w_3Q = 0;Exp_w_4Q = 0; 
Exp_rk_1Q = 0; Exp_rk_2Q = 0;Exp_rk_3Q = 0;Exp_rk_4Q = 0;

return
   
end
  

%% Generates expectations

if exp_gen == 1 

%% Computes forecasts of basic model variables  
  
for ctn_e = 1:length(bigT_vec)
    
  forcast_vec = ...
      inv(eye(n_var)-OMEGA_c)*(eye(n_var)-OMEGA_c^(bigT_vec(ctn_e)))*OMEGA_0+...
      OMEGA_c^(bigT_vec(ctn_e))*Y_var(:,ctn_s);
  
  %% This stores the forecast we are interested in. You have to remember 
  %% the location of the variable you are interested in forecasting (as in 
  %% the Model file.
  
  %% Timing: the first column of the expectations vector describes
  %% expectations taken in period 2 (ctn_s=2) on varibables in periods 3
  %% and beyond.
  
  Exp_Y_var{ctn_e}(:,ctn_s) = forcast_vec;
  
  %% Reminder (double check!): the order is: rk,w,y.
      
end 

 
%% HERE WE SIMULATE AGENT'FORECASTS, TO BE COMPARED WITH DATA

 
 %% 1. Forecast of return on the riskless asset

  Exp_R_1Q(ctn_s) = Exp_Y_var{1}(bond,ctn_s);
  
  
  Exp_R_3Q(ctn_s) = Exp_Y_var{3}(bond,ctn_s);

  
 %% 2. wage forecast

 
Exp_w_1Q(ctn_s) = Exp_Y_var{1}(wage,ctn_s); 

Exp_w_2Q(ctn_s) = Exp_Y_var{2}(wage,ctn_s);

Exp_w_3Q(ctn_s) = Exp_Y_var{3}(wage,ctn_s); 

Exp_w_4Q(ctn_s) = Exp_Y_var{4}(wage,ctn_s);


% 3. forecast of return to capital


Exp_rk_1Q(ctn_s) = Exp_Y_var{1}(rk,ctn_s);

Exp_rk_2Q(ctn_s) = Exp_Y_var{2}(rk,ctn_s);

Exp_rk_3Q(ctn_s) = Exp_Y_var{3}(rk,ctn_s);

Exp_rk_4Q(ctn_s) = Exp_Y_var{4}(rk,ctn_s);



end %% closes exp_gen loop 



%% UPDATE REGRESSORS



if learning == 1

    
    
    
%% update gain

if cg == 0
    
    g = (ctn_s+ini_gain)^(-1);
    
else
    
    g = g_gain;
    
end %% closes the if_cg loop



%% update regressors


 X_vec(1+n_c:end) = Y_var(cap,ctn_s-1); %% capital as only regressor here



Y_vec = Y_var(1:n_eq,ctn_s); 



if length(Y_vec) ~= n_eq
    
    disp('n. of regression eqs. different from n. of dependent. vars.')
break

end



%% update precision matrix

if sga == 0
   
 R_mat1 = R_mat+g*(X_vec*X_vec'-R_mat);
  
 
 %% checking the invertibility if the R matrix
 
  if rcond(R_mat1) < R_mat_tol
 
   disp('warning: singular R matrix')

   ct2 = 1; Y_var = 0; Exp_Y_var = 0;
            Regressors_ini = 0; R_mat_ini = 0;
            state_ini = 0; OMEGA_c_ini = 0; OMEGA_0_ini = 0;
           Exp_R_1Q = 0;Exp_R_3Q = 0; Exp_w_1Q = 0;
Exp_w_2Q = 0;Exp_w_3Q = 0;Exp_w_4Q = 0; 
Exp_rk_1Q = 0; Exp_rk_2Q = 0;Exp_rk_3Q = 0;Exp_rk_4Q = 0;

            return
   
  end
  
     
  R_inv = inv(R_mat1);
 
 
  
else   %% sga loop
    
    
 
%% Standard SG

% NOT AVAILABLE

%% GSG, Evans, Honkapohja and Williams (2006)

% NOT AVAILABLE

end %% closes the if_sga loop






%% update estimates

for ctn = 1:n_eq
    

 Regressors1{ctn} = Regressors{ctn}+g*R_inv*X_vec*(Y_vec(ctn)-Regressors{ctn}'*X_vec);



end


 


%% Projection facility: NOT ACTIVE NOW...

% if p_f == 1
%     
%     
%    for ctn = 1:n_eq
%        
%        for ctn1 = 1:n_x+n_c
%            
%        if abs(Regressors1{ctn}(ctn1)-Regressors_RE{ctn}(ctn1))...
%                >= pf_k*sigma_vec{ctn}(ctn1)
%            
%                 Regressors1{ctn}(ctn1) = Regressors{ctn}(ctn1);
%            end
%        
%        end 
% 
%    end
%    
%     
% end %% ends projection facility loop


%% ---special addition: model with capital (3rd regression equation)
%% Projection facility on CAPITAL coefficient

if abs(Regressors1{cap}(1+n_c)) > 0.99
    
    Regressors1{cap}(1+n_c) = Regressors{cap}(1+n_c);
    
end



%% Keeping track of the estimates

if store == 1
    
    for ctn = 1:n_eq
        
COEFF_STORE{ctn}(:,ctn_s-1) = Regressors1{ctn};   

    end
    
end %% close store loop



%% Update regressors vectors

for ctn = 1:n_eq
       
    
Regressors{ctn} = Regressors1{ctn};
 
    
end


%%... and the precision matrix

if sga == 0
    
R_mat = R_mat1;

end


%% Update OMEGA_0 and OMEGA_c

if feedback == 1

    
    
 if n_c == 1
    
for ctn = 1:n_eq
    
OMEGA_0(ctn) = Regressors{ctn}(1);

end

 end %% end n_c loop


if n_x > 0

for ctn = 1:n_eq    
  

  OMEGA_c(ctn,cap) = Regressors{ctn}(n_c+1:end);


 
end

end


%% FORECAST UNDER RE

[T_0_fre T_L_fre T_s_fre T_c_fre T_Ls_fre] = ALM_fun(A,C,invA0,OMEGA_0,OMEGA_c,k_y,disc);

forecst_RE = T_0_fre+T_L_fre*Y_var(:,ctn_s);

%forecstw(ctn_s) = forecst_RE(wage);    
%Exp_w_1Q(ctn_s) = forecst_RE(wage);   

end %% closes the if_feedback command


end %% closes the if_learning command


%% CREATES MATRICES FOR IMPULSE RESP. INITIAL CONDITIONS:

if imp_resp == 1

if ctn_s == sim_L+1  %% here: -- (end of 'training' sample)
 
    
    if full == 1
    

    
%% 1. Regressors_ini

Regressors_ini = Regressors;


%% 2. R_mat_ini

R_mat_ini = R_mat;


%% 3. state_ini

state_ini = Y_var(:,ctn_s);

OMEGA_c_ini  = OMEGA_c(:,cap);

OMEGA_0_ini = OMEGA_0; 
 
end %% ends full == 1 loop


end %% ends ctn_s == sim_L+1 loop


  if full == 0
    
        
 Regressors_ini = 0;  R_mat_ini = 0; state_ini = 0;
 OMEGA_c_ini = 0; OMEGA_0_ini = 0;
  
  end
 
end %% ends imp_resp loop 

 end %% end of simulation
 
 


 
%%  SAVE estimation coefficients
 
 if store == 1
     
     save COEFF_STORE_mat COEFF_STORE
     
 end

 
 
        
end  %% end the ct2 loop

 if ct2 == 1
            
            Y_var = 0; 
            Regressors_ini = 0; R_mat_ini = 0;
            state_ini = 0; OMEGA_c_ini = 0; OMEGA_0_ini = 0;
         Exp_R_1Q = 0;Exp_R_3Q = 0; Exp_w_1Q = 0;
Exp_w_2Q = 0;Exp_w_3Q = 0;Exp_w_4Q = 0; 
Exp_rk_1Q = 0; Exp_rk_2Q = 0;Exp_rk_3Q = 0;Exp_rk_4Q = 0;
   
            
        end
 
