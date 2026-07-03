%% THIS FUNCTION CONSTRUCTS THE MODEL IN MATRIX FORM
%% We include present value of labor income and capital income
%% in this version, the vector param includes:
% param(1): Infinite-horizon formulation flag
% param(2): External-effects parameter
% param(3): Utility-function parameter sigma
% param(4): Simple-RBC specification flag
% param(5): Inverse labor-supply elasticity
function [A,C,invA0,k_y,disc,invalid_params] = Model_Sept_2009(param)

% The model includes capital utilization, externalities and nonseparability between leisure and
% consumption
% NEW: here the mode include an infinite discounted expectation of wages
% and rental rates of capital

invalid_params = false; %% Control on bounds for calibrated coefficients
solvem = 1; %% Solve the model     %% set == 1 if want to solve del model

%% Choose Specs
inf_H = param(1); %% if set == 1 chooses inf. horizon approach, %% Otherwise Euler Aproach. %% In this file we ONLY have the IH approach
RBC_dummy = 1-param(4); %% set == 0 for simple RBC
partic = 0; %% set == 1 for model with partic. (NOT USED)

%% [1] DEFINE VARIABLES

n_var = 13; % total number of variables
n_exog_vars = 1; % number of exogenous variables
n_shocks = 1; %i.i.d. shocks

%% endogenous variables
idx = ir_variable_indices();

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

external_effects = param(2); %% external effects
sigma = param(3); %% parameter in the utility function
beta = 0.99*gamma^(sigma-1); %% adjusted discount rate (not really used...)

%% Verify parameters' bounds

if external_effects > 1 || sigma > 2.8 || sigma < 1
    A = {};
    C = [];
    invA0 = [];
    k_y = 1;
    disc = [];
    invalid_params = true;
    return;
end


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
R_bar = beta^(-1)-(1-delta)/gamma^(sigma); % Will — does not appear to be used anywhere
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

%% infinite forecasting horizon (different discount factors)
j_y = length(disc);

%% [4] DEFINE MATRICES
%% constant

Ac = zeros(n_var-n_exog_vars,1);
A{1} = [Ac;zeros(n_exog_vars,1)];


%% contemporaneous variables

A0 = zeros(n_var-n_exog_vars,n_var);

%% Household labor-supply condition
% wage_t - consumption_t - labor_supply_coefficient * hours_t = 0
A0(idx.wage, idx.wage) = 1;
A0(idx.wage, idx.consumption) = -1;
A0(idx.wage, idx.hours) = -(eps_H - psi*(sigma - 1)/sigma); %% eps_H defines elasticity

%% Firm labor-demand condition
% output_t - hours_t - wage_t = 0
A0(idx.hours, idx.output) = 1;
A0(idx.hours, idx.hours) = -1;
A0(idx.hours, idx.wage) = -1;

%% Rental rate of capital
% Relates the rental rate to output, technology growth, capital,
% and capacity utilization.
A0(idx.rk, idx.rk) = -1;
A0(idx.rk, idx.output) = 1;
A0(idx.rk, idx.gamma_x) = 1;
A0(idx.rk, idx.caput) = -RBC_dummy;

%% Aggregate resource constraint
% output_t = consumption_share * consumption_t + investment_share * investment_t
A0(idx.investment,idx.investment) = 1-cy_ratio;
A0(idx.investment,idx.consumption) = cy_ratio;
A0(idx.investment,idx.output) = -1;

%% Production function
% Output depends on hours, capital, capacity utilization,
% technology growth, and the production externality.
A0(idx.output, idx.output) = -1;
A0(idx.output, idx.mp) = 1;
A0(idx.output, idx.hours) = 1 - alpha;
A0(idx.output, idx.gamma_x) = -alpha;
A0(idx.output, idx.caput) = RBC_dummy*alpha;

%% Production externality
% Defines the external productivity term from aggregate inputs.
A0(idx.mp, idx.mp) = -1;
A0(idx.mp, idx.hours) = (1 - alpha)*external_effects;
A0(idx.mp, idx.gamma_x) = -external_effects*alpha;
A0(idx.mp, idx.caput) = RBC_dummy*external_effects*alpha;

%% Capital accumulation
% Relates current capital to investment, technology growth,
% capacity utilization, and lagged capital.
A0(idx.capital,idx.capital) = -1;
A0(idx.capital,idx.investment) = ik_ratio;
A0(idx.capital,idx.gamma_x) = -(1 - delta)/gamma;
A0(idx.capital,idx.caput) = -RBC_dummy*delta*theta/gamma;

%% Capacity-utilization condition
% With variable utilization:
%   utilization_t = rental_rate_t / (theta - 1)
A0(idx.caput, idx.caput) = 1;
A0(idx.caput, idx.rk) = -RBC_dummy/(theta - 1);


%% Auxiliary present-value variables

% Present value of expected labor income
A0(idx.w_sum, idx.w_sum) = 1;

% Inactive alternative formulation:
% A0(w_sum, wage) = -1;
%
% A0(w_sum, wage) = -(1 - beta_tilda)*...
%     (1 + (eps_c - eps_w) / ...
%     (eps_c*(eps_H - (sigma - 1)/sigma*psi)));
%
% A0(w_sum, rk) = ...
%     (1 - beta_tilda) / ...
%     (eps_c*(eps_H - (sigma - 1)/sigma*psi))*R_tilda;
%
% A0(w_sum, gamma_x) = ...
%     -(1 - beta_tilda) / ...
%     (eps_c*(eps_H - (sigma - 1)/sigma*psi));

% Present value of expected capital income
A0(idx.rk_sum, idx.rk_sum) = 1;

% Inactive alternative formulation:
% A0(rk_sum, w_sum) = 1;
%
% A0(rk_sum, wage) = ...
%     (eps_c*(eps_H - ((sigma - 1)/sigma)*psi))^(-1) ...
%     *(eps_w - eps_c);
%
% A0(rk_sum, rk) = ...
%     (eps_c*(eps_H - ((sigma - 1)/sigma)*psi))^(-1) ...
%     *R_tilda;
%
% A0(rk_sum, gamma_x) = ...
%     -(eps_c*(eps_H - ((sigma - 1)/sigma)*psi))^(-1) ...
%     *beta_tilda^(-1);
%
% A0(rk_sum, w_sum) = -1;
%
% A0(rk_sum, hours) = -sigma^(-1)*(1 - sigma)*psi;

%% Auxiliary bond equation
A0(idx.bond, idx.bond) = 1;


%% Consumption Equation
if inf_H == 0
    % One-period Euler-equation formulation
    A0(idx.consumption,idx.consumption) = sigma;
    A0(idx.consumption,idx.hours) = psi*(1 - sigma);

else
    % Infinite-horizon consumption decision rule
    A0(idx.consumption,idx.consumption) = 1;
    A0(idx.consumption,idx.hours) = sigma^(-1)*psi*(1 - sigma);
    A0(idx.consumption,idx.rk) = -c_c*R_tilda;
    A0(idx.consumption,idx.gamma_x) = c_c*beta_tilda^(-1);
    A0(idx.consumption,idx.wage) = ...
        -c_c*(eps_w+chi*eps_c/(1-chi));
end


%% Complete the contemporaneous system
% Append the identity equation for the exogenous variable, then invert.
A0_full = [
    A0;
    zeros(n_exog_vars, n_var - n_exog_vars), eye(n_exog_vars)
    ];

invA0 = inv(A0_full);



%% Expectations of current variables formed at t-1
% This model does not use this expectation category.
A{2} = zeros(n_var, n_var); % original comment said "lag expectaions"


%% Finite-horizon expectations
% A{3} multiplies E_t[y_{t+1}] because k_y = 1. #TODO figure out what this means
A{3} = zeros(n_var, n_var);

if inf_H == 0
    % One-period-ahead terms in the household Euler equation
    A{3}(idx.consumption,idx.rk) = -beta_tilda*R_tilda;
    A{3}(idx.consumption,idx.consumption) = sigma;
    A{3}(idx.consumption,idx.hours) = psi*(1-sigma);
    A{3}(idx.consumption,idx.gamma_x) = sigma;
end

% One-period-ahead return in the auxiliary bond equation
A{3}(idx.bond, idx.rk) = beta_tilda*R_tilda;



%% Infinite-horizon discounted expectations
% A{4} multiplies:
%   E_t sum_{h=1}^{infinity} beta_tilda^(h-1) y_{t+h}
A{4} = zeros(n_var, n_var);

if inf_H == 1
    % Expected future terms in the household consumption rule
    A{4}(idx.consumption,idx.gamma_x) = beta_tilda-c_c;

    A{4}(idx.consumption, idx.rk) = ...
        -beta_tilda*R_tilda ...
        *(beta_tilda*sigma^(-1) - c_c);

    A{4}(idx.consumption, idx.wage) = ...
        c_c*beta_tilda ...
        *(eps_w + eps_c*chi/(1 - chi));

    % Recursive discounted sum of future capital returns
    A{4}(idx.rk_sum, idx.rk) = beta_tilda;

    % Recursive discounted sum of future wages
    A{4}(idx.w_sum, idx.wage) = beta_tilda;

    % Inactive alternative formulation:
    % infinite expected discounted sum of rk and w
    % A{4}(w_sum, rk) = ...
    %     -(1 - beta_tilda) / ...
    %     (eps_c*(eps_H - (sigma - 1)/sigma*psi)) ...
    %     *beta_tilda*R_tilda;
    %
    % A{4}(w_sum, wage) = ...
    %     (1 - beta_tilda)*beta_tilda ...
    %     *(1 + (eps_c - eps_w) / ...
    %     (eps_c*(eps_H - (sigma - 1)/sigma*psi)));
    %
    % A{4}(w_sum, gamma_x) = ...
    %     (1 - beta_tilda) / ...
    %     (eps_c*(eps_H - (sigma - 1)/sigma*psi));
    %
    % A{4}(rk_sum, rk) = ...
    %     -(eps_c*(eps_H - ((sigma - 1)/sigma)*psi))^(-1) ...
    %     *beta_tilda*R_tilda;
    %
    % A{4}(rk_sum, wage) = ...
    %     -(eps_c*(eps_H - ((sigma - 1)/sigma)*psi))^(-1) ...
    %     *(eps_w - eps_c)*beta_tilda;
end


%% Predetermined and lagged variables
% A{5} multiplies y_{t-1}.
A{5} = zeros(n_var, n_var);


%% Lagged capital in the rental-rate equation
A{5}(idx.rk, idx.capital) = 1;


%% Exogenous technology-growth process
A{5}(idx.gamma_x, idx.gamma_x) = rho_x;


%% Lagged capital in capital accumulation
A{5}(idx.capital, idx.capital) = -(1 - delta)/gamma;


%% Lagged capital in production
A{5}(idx.output, idx.capital) = -alpha;


%% Lagged capital in the externality equation
A{5}(idx.mp, idx.capital) = -external_effects*alpha;

%% Lagged capital in the infinite-horizon consumption rule
if inf_H == 1
    A{5}(idx.consumption, idx.capital) = beta_tilda^(-1)*c_c;

    % Inactive alternative formulation:
    % A{5}(w_sum, capital) = ...
    %     -(1 - beta_tilda) / ...
    %     (eps_c*(eps_H - (sigma - 1)/sigma*psi)) ...
    %     *beta_tilda^(-1);
    %
    % A{5}(rk_sum, capital) = ...
    %     -(eps_c*(eps_H - ((sigma - 1)/sigma)*psi))^(-1) ...
    %     *beta_tilda^(-1);
end

%% Structural shocks (i.i.d.)
C = zeros(n_var, n_shocks);

% Innovation to technology growth
C(idx.gamma_x, idx.eps_x) = 1;

% Convert the structural shock into the solved contemporaneous system.
C = invA0*C;

%disp('matrices have been created')

%% Solve and convert to REDS-SOLDS
if solvem == 1
    ini_cond_0 = zeros(n_var,1);
    ini_cond = zeros(n_var,n_var);
    %ini_cond = OMEGA_c_RE;
    [OMEGA_0_RE, OMEGA_c_RE] = REE_solve(ini_cond_0,ini_cond,A,C,invA0,k_y,disc);

    [T_0_RE, T_L_RE, T_s_RE, T_c_RE, T_Ls_RE] = ...
        ALM_fun(A,C,invA0,OMEGA_0_RE,OMEGA_c_RE,k_y,disc);

    %% not active...
    % n_states = 2;
    %
    %  [D,F,G,H] = State_Space_convert(T_L_RE,T_s_RE,n_states,n_var);
end  %% closes solvem loop
