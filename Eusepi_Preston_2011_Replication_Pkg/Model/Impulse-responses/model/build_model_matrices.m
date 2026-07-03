%% Formerly Model_Sept_2009.m in this impulse-response folder.
%% Renamed to describe its current role: constructing model matrices.
%% THIS FUNCTION CONSTRUCTS THE MODEL IN MATRIX FORM
%% We include present value of labor income and capital income
%% in this version, the vector param includes:
% param(1): Infinite-horizon formulation flag
% param(2): External-effects parameter
% param(3): Utility-function parameter sigma
% param(4): Simple-RBC specification flag
% param(5): Inverse labor-supply elasticity
function [A,C,invA0,k_y,disc,invalid_params] = build_model_matrices(param)

% The model includes capital utilization, externalities and nonseparability between leisure and
% consumption
% NEW: here the mode include an infinite discounted expectation of wages
% and rental rates of capital

invalid_params = false; %% Control on bounds for calibrated coefficients
params = parse_model_parameters(param);

%% Choose Specs
inf_H = params.infinite_horizon; %% if set == 1 chooses inf. horizon approach, %% Otherwise Euler Aproach. %% In this file we ONLY have the IH approach
RBC_dummy = 1-params.simple_rbc; %% set == 0 for simple RBC
partic = 0; %% set == 1 for model with partic. (NOT USED)

%% [1] DEFINE VARIABLES

dims = model_dimensions();
n_var = dims.n_var;
n_exog_vars = dims.n_exog_vars;
n_shocks = dims.n_shocks;

%% endogenous variables
idx = ir_variable_indices();

%% forecasting horizon (finite)
k_y = dims.forecasting_horizon;

%% [2] DEFINE PARAMETERS

%% [a] CALIBRATED

delta = 0.025; %% depreciation rate
alpha = 0.34; %% capital share
rho_x = 0;  %% autoregressive coeff. in inv. neutral. shock
gamma = exp(0.0053); %% mean of gdp growth in current data
eps_H = params.inverse_labor_elasticity; %% inv. of elasticity of labor supply
phi_bar = 0.01; %% marginal cost of labor participation
calibration = struct( ...
    'delta', delta, ...
    'alpha', alpha, ...
    'gamma', gamma, ...
    'eps_H', eps_H);

%% [b] ESTIMATED (or just coming from another file)

%% [c] ESTIMATED PARAMETERS

external_effects = params.external_effects; %% external effects
sigma = params.sigma; %% parameter in the utility function
beta = 0.99*gamma^(sigma-1); %% adjusted discount rate (not really used...)
calibration.beta = beta;

%% Verify parameters' bounds

invalid_params = validate_model_parameters(params);

if invalid_params
    A = {};
    C = [];
    invA0 = [];
    k_y = dims.forecasting_horizon;
    disc = [];
    return;
end


%% [3] STEADY STATE
steady_state = calculate_model_steady_state(sigma, calibration, RBC_dummy, partic);
beta_tilda = steady_state.beta_tilda;
theta = steady_state.theta;
ik_ratio = steady_state.ik_ratio;
cy_ratio = steady_state.cy_ratio;
R_tilda = steady_state.R_tilda;
psi = steady_state.psi;
eps_c = steady_state.eps_c;
eps_w = steady_state.eps_w;
chi = steady_state.chi;
c_c = steady_state.c_c;

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
% Inactive alternatives archived in notes/inactive_model_equation_alternatives.m.

% Present value of expected capital income
A0(idx.rk_sum, idx.rk_sum) = 1;
% Inactive alternatives archived in notes/inactive_model_equation_alternatives.m.

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
    % Inactive alternatives archived in notes/inactive_model_equation_alternatives.m.
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
    % Inactive alternatives archived in notes/inactive_model_equation_alternatives.m.
end

%% Structural shocks (i.i.d.)
C = zeros(n_var, n_shocks);

% Innovation to technology growth
C(idx.gamma_x, idx.eps_x) = 1;

% Convert the structural shock into the solved contemporaneous system.
C = invA0*C;

%disp('matrices have been created')
