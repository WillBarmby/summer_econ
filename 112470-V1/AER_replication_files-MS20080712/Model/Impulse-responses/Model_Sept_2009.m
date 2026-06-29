

%% THIS FUNCTION CONSTRUCTS THE MODEL IN MATRIX FORM

%% in this version, the vector param includes: inf_H,sigma,eta,rho_z,rho_a 
%% We include present value of labor income and capital income

% function [A,C,invA0,k_y,disc,ct1] = Model_Sept_2009(param)


% The model includes capital utilization, externalities and nonseparability between leisure and
% consumption
% NEW: here the mode include an infinite discounted expectation of wages
% and rental rates of capital
 
 
%% Set param in case the file is not used as a function (comment otherwise)
 clear all 
 param(1) = 1;  %% IH
 param(2) = 0; %% External effects
 param(3) = 1; %% sigma
 param(4) = 1; %% simple RBC (Takes 1 or zero)
 param(5) = 0.0001; %% elasticity of labor supply
 param(6) = 0; %% 0 for standard nonsep, 1 for partic. model (NOT USED)

%% Control on bounds for calibrated coefficients

ct1 = 0;


%% Solve the model

solvem = 1;     %% set == 1 if want to solve del model




%% Choose Specs

 %% 1.
 
inf_H = param(1); %% if set == 1 chooses inf. horizon approach, 
                  %% Otherwise Euler Aproach.
                  %% In this file we ONLY have the IH approach

                  
 %% 2.

RBC_dummy = 1-param(4); %% set == 0 for simple RBC


 %% 3.

partic = 0; %% set == 1 for model with partic. (NOT USED)


%% The reference Sciword file is Simple_Models_file_12_Dec_2007.tex ??
%% check





%% [1] DEFINE VARIABLES


n_var = 13; % total number of variables

n_exos = 1; %exogenous variables

n_shocks = 1; %i.i.d. shocks



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


%% shocks
eps_x = 1;



%% forecasting horizon (finite)
k_y = 1;




%% [2] DEFINE PARAMETERS

%% [a] CALIBRATED





delta = 0.025; %% depreciation rate

alpha = 0.34; %% capital share

rho_x = 0;  %% autoregressive coeff. in inv. neutral. shock

gamma = exp(0.0053); %% mean of gdp growth in current data 

eps_H = param(5); %% inv. of elasticity of labor supply

phi_bar = 0.01; %% marginal cost of labor participation


%% [b] ESTIMATED (or just coming from another file)



%% [c] ESTIMATED PARAMETERS

  
  eta = param(2); %% external effects
  
  sigma = param(3); %% parameter in the utility function

  
  beta = 0.99*gamma^(sigma-1); %% adjusted discount rate (not really used...)
  

  %% Verify parameters' bounds
  
  if eta > 1 
      
      ct1 = 1;
  
      
  
  end
  
  if sigma > 2.8 | sigma < 1 
      
      ct1 = 1;
  
      
  
  end
  
  
  
  if ct1 == 0
  
  
 %% [3] STEADY STATE
 

%% Paramters of the capital production function


delta_tilda = 1-(1-delta)/gamma; %% investment to capital ratio

beta_tilda = beta*gamma^(1-sigma); %% modified discount rate

%% Steady State values of main variables


theta = (gamma*beta_tilda^(-1)-(1-delta))/delta;


if RBC_dummy == 0
    
    u_ss = 1;

else

    u_ss = (theta*delta)^(1/theta); %% capital utilization

end



yk_ratio = delta*theta/(alpha*gamma);

ik_ratio = delta_tilda;

ck_ratio = yk_ratio-ik_ratio;

cy_ratio = ck_ratio/yk_ratio;

R_bar = beta^(-1)-(1-delta)/gamma^(sigma);

delta_s = (1-delta)/gamma;

R_tilda = beta_tilda^(-1)-delta_s;

psi = cy_ratio^(-1)*(1-alpha);



%% coeffs. convolutions of parameters



if partic == 0
    
eps_c = ck_ratio+(eps_H-psi*(sigma-1)/sigma)^(-1)*R_tilda*(1-alpha)/alpha;

eps_w = (1+(eps_H-psi*(sigma-1)/sigma)^(-1))*R_tilda*(1-alpha)/alpha;

chi = psi*(1-sigma)/(sigma*eps_H+psi*(1-sigma));

c_c = (1-beta_tilda)*(1-chi)/eps_c;

else
    
%%TO BE ADDED  

end 





%% discounts

disc = [beta_tilda]; %% NOTE: if take Euler Approach, just set disc as having one



%% inifinte forecasting horizon (different discount factors)
j_y = length(disc);




%% [4] DEFINE MATRICES

%% constant

Ac = zeros(n_var-n_exos,1);

A{1} = [Ac;zeros(n_exos,1)];


%% contemporaneous variables

A0 = zeros(n_var-n_exos,n_var);



A0(wage,hours) = -(eps_H-psi*(sigma-1)/sigma); %% eps_H defines elasticity
 
A0(wage,cons) = -1;

A0(wage,wage) = 1;


A0(hours,hours) = -1;

A0(hours,output) = 1;

A0(hours,wage) = -1;


A0(rk,rk) = -1;

A0(rk,gamma_x) = 1;

A0(rk,output) = 1;

A0(rk,caput) = RBC_dummy*(-1);


A0(invst,invst) = (1-cy_ratio);

A0(invst,cons) = (cy_ratio);

A0(invst,output) = -1;



A0(output,output) = -1;

A0(output,mp) = 1;

A0(output,hours) = 1-alpha;

A0(output,gamma_x) = -alpha;

A0(output,caput) = RBC_dummy*alpha;


A0(mp,mp) = -1;

A0(mp,hours) = (1-alpha)*eta;

A0(mp,gamma_x) = -eta*alpha;

A0(mp,caput) = RBC_dummy*eta*alpha;





A0(cap,cap) = -1;

A0(cap,invst) = ik_ratio;

A0(cap,gamma_x) = -((1-delta)/gamma);

A0(cap,caput) = RBC_dummy*(-delta*theta/gamma);


A0(caput,caput) = 1;

A0(caput,rk) = RBC_dummy*(-1/(theta-1));




A0(w_sum, w_sum) = 1;

%A0(w_sum, wage) = -1;

% A0(w_sum, wage) = -(1-beta_tilda)*...
%                    (1+(eps_c-eps_w)/(eps_c*(eps_H-(sigma-1)/sigma*psi)));
%                
% A0(w_sum, rk) =  (1-beta_tilda)/(eps_c*(eps_H-(sigma-1)/sigma*psi))*...
%                    R_tilda;
               
% A0(w_sum, gamma_x) = -(1-beta_tilda)/(eps_c*(eps_H-(sigma-1)/sigma*psi));



A0(rk_sum,rk_sum) = 1;

% A0(rk_sum,w_sum) = 1;
% 
%  A0(rk_sum,wage) = (eps_c*(eps_H-((sigma-1)/sigma)*psi))^(-1)*(eps_w-eps_c);
% A0(rk_sum,rk) =  (eps_c*(eps_H-((sigma-1)/sigma)*psi))^(-1)*R_tilda; 
% A0(rk_sum,gamma_x) =  -(eps_c*(eps_H-((sigma-1)/sigma)*psi))^(-1)*beta_tilda^(-1);
%A0(rk_sum,w_sum) = -1;
% A0(rk_sum,hours) = -sigma^(-1)*(1-sigma)*psi;


A0(bond,bond) = 1;

%% Consumption Equation

 if inf_H == 0
     
A0(cons,cons) = sigma;

A0(cons,hours) = psi*(1-sigma);


 else 
     
     
     A0(cons,cons) = 1;
     
     A0(cons,hours) = sigma^(-1)*psi*(1-sigma);
  
     A0(cons,rk) = -c_c*R_tilda;
     
     A0(cons,gamma_x) = c_c*beta_tilda^(-1);

     A0(cons,wage) = -c_c*(eps_w+chi*eps_c/(1-chi));

 end
     
     
     
     



invA0 = inv([A0 ,
        zeros(n_exos,n_var-n_exos) eye(n_exos)]);
  
        
 %% lag expectaions       

A{2} = zeros(n_var,n_var);



%% forward looking (finite)

A{3} = zeros(n_var,n_var);


if inf_H == 0
    
    
 A{3}(cons,rk) = -beta_tilda*R_tilda;
 
 A{3}(cons,cons) = sigma;
 
 A{3}(cons,hours) = psi*(1-sigma);
 
 A{3}(cons,gamma_x) = sigma;

  
 
end  
  

A{3}(bond,rk) = beta_tilda*R_tilda;


%% infinite horizon

A{4} = zeros(n_var,n_var);


if inf_H == 1



A{4}(cons,gamma_x) = beta_tilda-c_c;



A{4}(cons,rk) = -beta_tilda*R_tilda*(beta_tilda*sigma^(-1)-c_c);



A{4}(cons,wage) = c_c*beta_tilda*(eps_w+eps_c*chi/(1-chi));


% infinte expected discounted sum of rk and w

% A{4}(w_sum,rk) = -(1-beta_tilda)/(eps_c*(eps_H-(sigma-1)/sigma*psi))*...
%                    beta_tilda*R_tilda;
% 
% 
% A{4}(w_sum,wage) = (1-beta_tilda)*beta_tilda*...
%                    (1+(eps_c-eps_w)/(eps_c*(eps_H-(sigma-1)/sigma*psi)));
% 
%                
% A{4}(w_sum,gamma_x) = (1-beta_tilda)/(eps_c*(eps_H-(sigma-1)/sigma*psi));
               
 A{4}(rk_sum,rk) = beta_tilda;

% A{4}(rk_sum,rk) = -(eps_c*(eps_H-((sigma-1)/sigma)*psi))^(-1)*beta_tilda*R_tilda;
% A{4}(rk_sum,wage) = -(eps_c*(eps_H-((sigma-1)/sigma)*psi))^(-1)*(eps_w-eps_c)*beta_tilda;

A{4}(w_sum,wage) = beta_tilda;


end





%% lagged variables

A{5} = zeros(n_var,n_var);


 
 A{5}(rk,cap) = 1;
 
 A{5}(gamma_x,gamma_x) = rho_x;

 A{5}(cap,cap) = -(1-delta)/gamma;
 
 A{5}(output,cap) = -alpha;
 
 A{5}(mp,cap) = -eta*alpha;
 
 
 
 if inf_H == 1   
     
 
  A{5}(cons,cap) = beta_tilda^(-1)*c_c;    

%   A{5}(w_sum,cap) = -(1-beta_tilda)/(eps_c*(eps_H-(sigma-1)/sigma*psi))*...
%                     beta_tilda^(-1);
%   
 %A{5}(rk_sum,cap) = -(eps_c*(eps_H-((sigma-1)/sigma)*psi))^(-1)*beta_tilda^(-1);
  
 end
 
 
 %% Shocks (i.i.d.)
 
 C = zeros(n_var,n_shocks);
 
  
 C(gamma_x,eps_x) = 1;
 
  
 
 C = invA0*C;
 
 
 %disp('matrices have been created')
 

 %% Solve and convert to REDS-SOLDS

 if solvem == 1
 
ini_cond_0 = zeros(n_var,1);

ini_cond = zeros(n_var,n_var);


%ini_cond = OMEGA_c_RE;
[OMEGA_0_RE OMEGA_c_RE] = REE_solve(ini_cond_0,ini_cond,A,C,invA0,k_y,disc);


[T_0_RE T_L_RE T_s_RE T_c_RE T_Ls_RE] = ...
   ALM_fun(A,C,invA0,OMEGA_0_RE,OMEGA_c_RE,k_y,disc);

%% not active...
% n_states = 2; 
%    
%  [D,F,G,H] = State_Space_convert(T_L_RE,T_s_RE,n_states,n_var);
 
 end  %% closes solvem loop
 
  end %% closes ct1 loop
 