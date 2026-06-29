
%%% THIS FILE COMPUTES THE MATRICES FOR THE MODEL SOLUTION
%%% INCLUDING INVESTMENT ADJUSTMENT COSTS


 
   
   function [A,B,C,NY,NX,NK] = external_habit_model_new(param)
 
 global zeta

%% NOTE: the vector param includes all the parameters.
%% IMPORTANT: verify that the vector param contain te same parameters as in
%% the Model file!



 %zeta = 0.7;
 
%% Simulate estimated model

%  clear all
% x = [ -2.8587
%    -5.0582
%    -2.5442
%   -19.8412
%   -19.2822
%   -13.0006
%    -2.4470
%      ];
%  
%  std_vec_s = [exp(x(1));exp(x(2));exp(x(3));exp(-30);exp(x(4));exp(x(5));exp(x(6));exp(x(7))];
% %std_vec_s = [exp(0);exp(0);exp(0);exp(0);exp(0);exp(0);exp(0);exp(0)];
% 
% zeta = 0.57; 
%      param(1) = 1.5; param(2) = 1; param(3) = 4^(-1)*param(2)/zeta; param(4) = 0; 
%      param(5) = 0.5; param(6) = 0.15; param(7) = 0.8;
%      param(8) = 0.99; param(9) = 0.85; param(10) = 0.9; param(11) = 0.99; param(12) = 0.5;
%      param(13) = -0.3; param(14) = 0.0053;

%% Comment is use as function file
 
%        clear all
% %  
%      zeta = 0.57; 
%      param(1) = 1.5; param(2) = 1; param(3) = 4^(-1)*param(2)/zeta; param(4) = 0; 
%      param(5) = 0.0; param(6) = 0.404; param(7) = 0.8;
%      param(8) = 0.9;
%      
%      param(9) = 0.8; param(10) = 0.8; param(11) = 0.99; param(12) = 0.55; param(13) = 0;
%       
% LIST OF PARAMETERS
%  phi_N = param(2); %% elst. in individual labor supply
%   
%   sigma = param(1); %% parameter in the utility function
% 
%   phi_ee = param(3); %% elst. labor participation
% 
%   eta = param(4); %% externality
% 
%   phi_i = param(5); %% invst adj. costs 
%  
%   eps_delta = param(6); %% cap utilization
% 
%   omega = param(7); %% unempl. consumption
%   
%   rho_g = param(8); %% autocorrelation of neutral shock
%   
%   rho_a = param(10); %% autoregressive coeff. in tfp shock
%   
%   rho_rw = param(13); %% autocorrelation of nonstat neutral shock
% 
%   rho_i = param(9);  %% autoregressive coeff. in inv. spec. shock
%   
%   rho_p = param(11); %% autocorrelation of part. shock
%   
%   nu = param(12); %% habit parameter
%
%   gamma_a = param(14); %% ss growth rate
%
%   
%%%%-------------------------------------------------------
%% Control on bounds for calibrated coefficients

%ct1 = 0;

%% [1] DEFINE VARIABLES




%% endogenous variables

% jump

rk = 1;
wage = 2;
output = 4;
tot_hours = 5;
cons = 6;
invst = 7;
partic = 3; 
caput = 8;
indiv_hours = 9;
cons_e = 10;
cons_u = 11;
lab_prod = 12;
inv_mult = 13;
lambda_mult = 14;
cons_growth = 15;
inv_growth = 16;
hours_growth = 17;
output_growth = 18;
prod_growth = 19;
invstq = 20;
int = 21;


% state
cap = 22;
cons_lag = 23;
inv_lag = 24;
tot_hours_lag = 25;
output_lag = 26;
wage_lag  = 27;
inv_shock = 28;
tfp_shock = 29;
gov_shock = 30; 
part_shock = 31;
tfp_shock_rw = 32; 

ni_shock = 33; % iid shock
n_g_shock = 34; % iid shock
n_rw_shock = 35;% iid shock
n_p_shock = 36;% iid shock
n_a0_shock = 37; % iid shock (last before lagged shocks)

 



%% shocks
n_i = 1;

n_g = 2;

n_rw = 3;

n_p = 4;

n_a0 = 5;

n_a1 = 6;

n_a2 = 7;

n_a3 = 8;


%% NOTE: we have 4 shocks affecting stationary TFP (n_as)


%% [2] DEFINE PARAMETERS

%% [a] CALIBRATED


delta = 0.025; %% depreciation rate

alpha = 0.34; %% capital share

% n_ss = 0.3; %% steady state hours (not used)

e_ss = 0.68; %% steady state participation 

g = 0.00000002; %% ratio of gov. spending to gdp

beta = 0.99;



%gamma_a = exp(0.0053);

%omega = 0.8; %% ratio between consumption of unemployed and employed

%zeta = 0.2; %% cost of participating as a fraction of wage earnings 

sigma_calib = 1; %% set==1 if you want to calibrate sigma as a function of 
                 %%the cost of participating
                 
theta_calib = 0; %% set ==1 to calibrate caput as function of dicount rate and deprec

%% [c] 'ESTIMATED' PARAMETERS

  phi_N = param(2); %% elst. in individual labor supply
  
  sigma = param(1); %% parameter in the utility function

  phi_ee = param(3); %% elst. labor participation

  eta = param(4); %% externality

  phi_i = param(5); %% invst adj. costs 
 
  eps_delta = param(6); %% cap utilization

  omega = param(7); %% unempl. consumption
  
  rho_g = param(8); %% autocorrelation of neutral shock
  
  rho_a = param(10); %% autoregressive coeff. in tfp shock
  
  rho_rw = param(13); %% autocorrelation of nonstat neutral shock

  rho_i = param(9);  %% autoregressive coeff. in inv. spec. shock
  
  rho_p = param(11); %% autocorrelation of part. shock
  
  nu = param(12); %% habit parameter
  
  gamma_a = exp(param(14)); %% ss growth rate
  
%   if sigma < 1.01
%       
%       omega = 0.999999;
%       
%   end

 % if ct1 == 0  
      
  
%% [3] STEADY STATE
 

%% Compute steady state (part I)

beta_tilda = beta/gamma_a; %% discount rate times the steady state growth rate of tech.

r_ku = beta_tilda^(-1)-1+delta;

yk_ratio = r_ku/(gamma_a*alpha);

ik_ratio = 1-(1-delta)/gamma_a;

ck_ratio = (1-g)*yk_ratio-ik_ratio;

cy_ratio = ck_ratio/yk_ratio;

psi = (1-alpha)*(cy_ratio)^(-1);

zeta_lam_fixed = zeta*psi;

iy_ratio = 1-cy_ratio-g;

s_e = e_ss/(e_ss+(1-e_ss)*omega);


if sigma_calib == 1
 
  sigma = (1-zeta)/(1-zeta-((1-omega)*psi^(-1)*s_e));
  
  zeta_lam = zeta_lam_fixed;
 
else
    
zeta_lam = psi-(sigma/(sigma-1))*(1-omega)*s_e;


end

if theta_calib == 1
    
    theta = (beta_tilda^(-1)-(1-delta))/delta;
    
    eps_delta = theta-1;
    
end

if zeta_lam < 0
    
    disp('wrong calibration')
    return
end

%% Bound on firsh elasticity is

phi_N_bound = psi*(sigma-1)/sigma*(s_e-nu*gamma_a^(-1)*e_ss)^(-1);

Phi_N_bound_new = ((1-omega)/(1-zeta))*(1-e_ss*nu*gamma_a^(-1)*(1+(e_ss^-1-1)*omega))^(-1);


%% Bound on habit

nu_bound = omega*s_e-nu*gamma_a^(-1)*e_ss;


%% Implied discount

beta = beta_tilda*gamma_a^sigma;

 
 %%  MODEL SOLUTION 
 
 A = zeros(n_a0_shock+6,n_a0_shock+6); %% there are six extra variables and is Schmitt Grohe' and Uribe what's news paper
 
 B = A;

 
A(lambda_mult,lambda_mult) = 1-beta_tilda*(1-delta);

A(lambda_mult,rk) = 1-beta_tilda*(1-delta);

A(lambda_mult,inv_mult) = beta_tilda*(1-delta);

A(lambda_mult,tfp_shock_rw) = -sigma*rho_rw;


A(inv_mult,invst) = beta_tilda*gamma_a^3*phi_i;

A(inv_mult,tfp_shock_rw) = beta_tilda*gamma_a^3*phi_i*rho_rw; 

A(inv_mult,inv_shock) = 1;

A(inv_mult,tfp_shock_rw) = -gamma_a^2*phi_i;


A(invstq,inv_shock) = 1;

A(cons_e,tfp_shock_rw) = -nu*gamma_a^(-1)*e_ss/(s_e-nu*gamma_a^(-1)*e_ss);


A(cons_u,tfp_shock_rw) = -nu*gamma_a^(-1)*e_ss/(omega*s_e-nu*gamma_a^(-1)*e_ss);


A(partic,part_shock) = ((sigma-1)/sigma)*zeta_lam;


A(cap,cap) = 1;

A(cap,tfp_shock_rw) = (1-delta)/gamma_a;


A(output,tfp_shock) = -1;

A(output,tfp_shock_rw) = alpha;


A(rk,tfp_shock_rw) = -1;


A(invst,gov_shock) = 1;


% A(invst,gov_shock) = g; % in case of the calibrated g


A(invst,inv_shock) = -iy_ratio;


A(int,lambda_mult) = 1;


% Growth rates

A(cons_growth,tfp_shock_rw) = -1;

A(inv_growth,tfp_shock_rw) = -1;

A(inv_growth,inv_shock) = 1;

A(output_growth,tfp_shock_rw) = -1;

A(prod_growth,tfp_shock_rw) = -1;


% Lags
A(cons_lag,cons_lag) = 1;

A(inv_lag,inv_lag) = 1;

A(tot_hours_lag,tot_hours_lag) = 1;

A(output_lag,output_lag) = 1;

A(wage_lag,wage_lag) = 1;


% Shocks
A(inv_shock,inv_shock) = 1;

A(tfp_shock,tfp_shock) = 1;

A(gov_shock,gov_shock) = 1;

A(tfp_shock_rw,tfp_shock_rw) = 1; 

A(part_shock,part_shock) = 1;


A(n_a0_shock+1:end,n_a0_shock+1:end) = eye(6);


A(ni_shock,ni_shock) = 1;

A(n_a0_shock,n_a0_shock) = 1;

A(n_rw_shock,n_rw_shock) = 1;

A(n_p_shock,n_p_shock) = 1;

A(n_g_shock,n_g_shock) = 1;





%% B matrix

B(lambda_mult,inv_mult) = 1;


B(inv_mult,inv_mult) = -1;

B(inv_mult,lambda_mult) = 1;

B(inv_mult,invst) = (beta_tilda*gamma_a+1)*gamma_a^2*phi_i;

B(inv_mult,inv_lag) = -phi_i*gamma_a^2;



B(wage,output) = 1; 

B(wage,wage) = -1;

B(wage,tot_hours) = -1;


 

B(indiv_hours,indiv_hours) = phi_N;

B(indiv_hours,wage) = -1;

B(indiv_hours,lambda_mult) = -sigma^(-1);



B(cons_e,cons_e) = s_e/(s_e-nu*gamma_a^(-1)*e_ss);

B(cons_e,indiv_hours) = -psi*(sigma-1)/(sigma*(s_e-nu*gamma_a^(-1)*e_ss));

B(cons_e,lambda_mult) = sigma^(-1);

B(cons_e,cons_lag) = -nu*gamma_a^(-1)*e_ss/(s_e-nu*gamma_a^(-1)*e_ss);


 %% Alternative eq without habit (do not use)
% B(cons_e,cons_e) = -1;
% 
% if omega < 0.99
% 
% B(cons_e,indiv_hours) = ((sigma-1)/sigma)*psi*s_e^(-1);
% 
% end
% 
% B(cons_e,cons_u) = 1;


B(output,tot_hours) = (1-alpha)*(1+eta);

B(output,output) = -1;

B(output,cap) = alpha*(1+eta);

B(output,caput) = alpha*(1+eta);




B(partic,partic) = ((sigma-1)/sigma)*phi_ee*zeta_lam;

B(partic,lambda_mult) = -((sigma-1)/sigma)*zeta_lam;

B(partic,wage) = -((sigma-1)/sigma)*psi;

B(partic,indiv_hours) = -((sigma-1)/sigma)*psi;

B(partic,cons_e) = s_e;

B(partic,cons_u) = -omega*s_e;




 B(cons_u,cons_u) = omega*s_e/(omega*s_e-nu*gamma_a^(-1)*e_ss);

 B(cons_u,lambda_mult) = sigma^(-1);
 
 B(cons_u,cons_lag) = -nu*gamma_a^(-1)*e_ss/(omega*s_e-nu*gamma_a^(-1)*e_ss);



B(cons,cons) = -1;

B(cons,cons_e) = s_e;

B(cons,cons_u) = 1-s_e;

B(cons,partic) = (1-omega)*s_e;



B(tot_hours,tot_hours) = -1;

B(tot_hours,partic) = 1;

B(tot_hours,indiv_hours) = 1;



B(caput,caput) = -eps_delta;

B(caput,rk) = 1;

B(caput,lambda_mult) = 1;

B(caput,inv_mult) = -1;




B(rk,rk) = -1;

B(rk,output) = 1;

B(rk,cap) = -1;

B(rk,caput) = -1;



B(cap,cap) = (1-delta)/gamma_a;

B(cap,invst) = ik_ratio;

B(cap,caput) = -(beta_tilda^(-1)-(1-delta))/gamma_a;



B(invst,invst) = -iy_ratio;

B(invst,cons) = -cy_ratio;

B(invst,output) = 1;


B(invstq,invstq) = -1;

B(invstq,invst) = 1;


B(lab_prod,lab_prod) = -1;

B(lab_prod,output)  = 1;

B(lab_prod,tot_hours) = -1;


B(int,lambda_mult) = 1;

B(int,int) = -1;


% Growth rates

B(cons_growth,cons_growth) = -1;

B(cons_growth,cons) = 1;

B(cons_growth,cons_lag) = -1;


B(hours_growth,hours_growth) = -1;

B(hours_growth,tot_hours) = 1;

B(hours_growth,tot_hours_lag) = -1;


B(inv_growth,inv_growth) = -1;

B(inv_growth,invst) = 1;

B(inv_growth,inv_lag) = -1;

B(inv_growth,inv_shock) = 1;


B(output_growth,output_growth) = -1;

B(output_growth,output) = 1;

B(output_growth,output_lag) = -1;


B(prod_growth,prod_growth) = -1;

B(prod_growth,wage) = 1;

B(prod_growth,wage_lag) = -1;


% Lags

B(cons_lag,cons) = 1;

B(inv_lag,invst) = 1;

B(tot_hours_lag,tot_hours) = 1;

B(output_lag,output) = 1;

B(wage_lag,wage) = 1;


% Shocks

B(inv_shock,inv_shock) = rho_i;

B(tfp_shock_rw,tfp_shock_rw) = rho_rw;

B(gov_shock,gov_shock) = rho_g;

B(part_shock,part_shock) = rho_p;


 % tfp process

B(tfp_shock,tfp_shock) = rho_a;
 
B(tfp_shock,n_a0_shock+1:end) = [1 0 0 1 0 1]; %% lagged shocks affecting tfp

B(n_a0_shock+4:end,n_a0_shock+1:end) = [0 1 0 0 0 0
                                      0 0 1 0 0 0
                                      0 0 0 0 1 0];


B(ni_shock,ni_shock) = 0;

B(n_a0_shock,n_a0_shock) = 0;

B(n_rw_shock,n_rw_shock) = 0;

B(n_p_shock,n_p_shock) = 0;

B(n_g_shock,n_g_shock) = 0;




 %% Shocks (i.i.d.)

% n_i = 1;
% 
% n_g = 2;
% 
% n_rw = 3;
% 
% n_p = 4;
% 
% n_a0 = 5;
% 
% n_a1 = 6;
% 
% n_a2 = 7;
% 
% n_a3 = 8;


C = zeros(n_a0_shock+6,8);

C(inv_shock,n_i) = 1;

C(tfp_shock,n_a0) = 1;

C(gov_shock,n_g) = 1;

C(tfp_shock_rw,n_rw) = 1;

C(part_shock,n_p) = 1;


C(ni_shock,n_i) = 1;

C(n_rw_shock,n_rw) = 1;

C(n_p_shock,n_p) = 1;

C(n_g_shock,n_g) = 1;



C(n_a0_shock,n_a0) = 1;

C(n_a0_shock+1:end,n_a1) = [1;zeros(5,1)];

C(n_a0_shock+1:end,n_a2) = [0;1;zeros(4,1)];

C(n_a0_shock+1:end,n_a3) = [0;0;1;zeros(3,1)];


NY = 37+6; NK = 22; NX = 8;


%% COMPUTE IMPULSE RESPONSESE

  %% define states
 
 

%  [Br,Cr,Lr,NF] = redsf(A,B,C,NY,NX,NK);
%  
%  [D,F,G,H] = soldsf(Br,Cr,Lr,NY,NX,NK,NF);
%  
%  D=real(D); F=real(F); G=real(G); H=real(H);
% 
%  
% 
% 
%  NIR = 25;
% 
%  %% shocks
% % n_i = 1;
% % 
% % n_g = 2;
% % 
% % n_rw = 3;
% % 
% % n_p = 4;
% % 
% % n_a0 = 5;
% % 
% % n_a1 = 6;
% % 
% % n_a2 = 7;
% % 
% % n_a3 = 8;
% 
%  
%   SHOCK = n_i;
%  
%   
%  
% imp_resp = irf(SHOCK, NIR, D, F, G, H, std_vec_s);
% 

% 
% %% Compute variable response in deviation from det. trend
% 
% imp_resp_dt = zeros(4,NIR); %% includes: cons,inv,out,prod
% 
%  imp_resp_dt(:,1) = [imp_resp(15:16,1);imp_resp(18:19,1)];  
%  
%  
%  for j = 2:NIR
%  
%  imp_resp_dt(:,j) = [imp_resp(15:16,j);imp_resp(18:19,j)]+imp_resp_dt(:,j-1);
%      
%  end




%   end %% ends ct1 loop


% %% COMPUTE POPULATION MOMENTS
% VCVX = zeros(size(C,2),size(C,2));
% 
% VCVX(SHOCK,SHOCK) = 1;
% 
% VCVK = vcv(VCVX, G, H);
% 
% %% Variance covariance matrix
% 
% LAG = 0;
% 
% ACM = acm(LAG, VCVX, VCVK, D, F, G, H);
% 
% %% Autocorrelation function
% 
% NACF = 2;
% 
% ACF = acf(NACF, VCVX, VCVK, D, F, G, H);
% 
% %% COMPUTE MOMENTS FOR THE VARIABLES OF INTEREST
% 
% % rk = 1;
% % wage = 2;
% % output = 4;
% % tot_hours = 5;
% % cons = 6;
% % invst = 7;
% % partic = 3; 
% % caput = 8;
% % indiv_hours = 9;
% % cons_e = 10;
% % cons_u = 11;
% % lab_prod = 12;
% % inv_mult = 13;
% % lambda_mult = 14;
% 
% 
%  %% Relative std 
%  
%  std_output = sqrt(ACM(output,output));
%  
%  cons_output = sqrt(ACM(cons,cons))/std_output;
%  
%  invst_output = sqrt(ACM(invst,invst))/std_output;
%  
%  lab_prod_output = sqrt(ACM(lab_prod,lab_prod))/std_output;
%  
%  % wage_output = sqrt(ACM(wage,wage))/std_output; % same as productivity
%  
%  tot_hours_output = sqrt(ACM(tot_hours,tot_hours))/std_output;
%  
%  partic_indiv_hours = sqrt(ACM(partic,partic))/sqrt(ACM(indiv_hours,indiv_hours));
%  
%  %% Correlations
%  
%  corr_output_cons = ACM(cons,output)/(sqrt(ACM(cons,cons))*std_output);
% 
%  corr_output_invst = ACM(invst,output)/(sqrt(ACM(invst,invst))*std_output);
%  
%  corr_output_lab_prod = ACM(lab_prod,output)/(sqrt(ACM(lab_prod,lab_prod))*std_output);
%  
%  corr_output_tot_hours = ACM(tot_hours,output)/(sqrt(ACM(tot_hours,tot_hours))*std_output);
%  
%  %% Autocorrelation
%  
%  auto_cons = ACF(cons,2)/ACM(cons,cons);
%  
