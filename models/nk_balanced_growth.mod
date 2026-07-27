// Stationary nonlinear New Keynesian model with capital and balanced growth.
// Source: docs/model_simple_dynare.tex, compact twelve-equation block.
// Dynare computes the deterministic steady state and analytical first-order
// approximation; this file does not contain a separate hand-linearized model.
//
// TeX-to-Dynare names:
//   r_t^k                 -> rk
//   w_t                   -> wage
//   y_t                   -> output
//   n_t                   -> hours
//   c_t                   -> consumption
//   i_t                   -> investment
//   k_t                   -> capital(-1)
//   k_(t+1)               -> capital
//   pi_t                  -> inflation
//   r_t                   -> nominal_rate
//   Psi_t                 -> marginal_cost
//   s_t                   -> risk_premium
//   gamma_hat_t           -> gamma_x
//   epsilon_t^Gamma       -> eps_x
//   epsilon_t^s           -> eps_s
//   Gamma_t               -> model-local Gamma
//   Gamma_(t+1)           -> model-local Gamma_lead

var rk wage output hours consumption investment capital inflation
    nominal_rate marginal_cost risk_premium gamma_x;
varexo eps_x eps_s;

parameters beta chi eta delta alpha theta phi_rot pi_bar phi_pi phi_y
    r_star gamma_bar rho_x sigma_x risk_premium_bar rho_s sigma_s hours_bar;
parameters rk_bar marginal_cost_bar output_bar capital_bar
    investment_bar consumption_bar wage_bar nominal_rate_bar;

// Macro defaults let MATLAB configs override calibration without editing this
// model file. For example, Dynare's -Drho_x=0.5 changes only persistence.
@#ifndef beta
    @#define beta = 0.995
@#endif
@#ifndef eta
    @#define eta = 0.3333333333333333
@#endif
@#ifndef delta
    @#define delta = 0.025
@#endif
@#ifndef alpha
    @#define alpha = 0.33
@#endif
@#ifndef theta
    @#define theta = 6
@#endif
@#ifndef phi_rot
    @#define phi_rot = 59.11
@#endif
@#ifndef pi_bar
    @#define pi_bar = 1.006
@#endif
@#ifndef phi_pi
    @#define phi_pi = 1.5
@#endif
@#ifndef phi_y
    @#define phi_y = 0.1
@#endif
@#ifndef gamma_bar
    @#define gamma_bar = 1.0053140698457452
@#endif
@#ifndef rho_x
    @#define rho_x = 0
@#endif
@#ifndef sigma_x
    @#define sigma_x = 0.01
@#endif
@#ifndef risk_premium_bar
    @#define risk_premium_bar = 1
@#endif
@#ifndef rho_s
    @#define rho_s = 0
@#endif
@#ifndef sigma_s
    @#define sigma_s = 0
@#endif
@#ifndef hours_bar
    @#define hours_bar = 0.3333333333333333
@#endif

// Structural calibration from docs/model_simple_dynare.tex.
beta = @{beta};
eta = @{eta};
delta = @{delta};
alpha = @{alpha};
theta = @{theta};
phi_rot = @{phi_rot};
pi_bar = @{pi_bar};
phi_pi = @{phi_pi};
phi_y = @{phi_y};
gamma_bar = @{gamma_bar};
rho_x = @{rho_x};

// A unit eps_x is a one-percentage-point innovation to log technology growth.
// The canonical loader will express gamma_x in percentage-point units as well.
sigma_x = @{sigma_x};

// The risk-premium extension is dormant in the baseline.
risk_premium_bar = @{risk_premium_bar};
rho_s = @{rho_s};
sigma_s = @{sigma_s};
hours_bar = @{hours_bar};

// Algebraic balanced-growth steady state derived in the source TeX file.
rk_bar = gamma_bar/beta-(1-delta);
marginal_cost_bar = (theta-1)/theta;
output_bar = (alpha*marginal_cost_bar/rk_bar)^(alpha/(1-alpha))*hours_bar;
capital_bar = alpha*marginal_cost_bar*gamma_bar/rk_bar*output_bar;
investment_bar = (1-(1-delta)/gamma_bar)*capital_bar;
consumption_bar = output_bar-investment_bar;
wage_bar = (1-alpha)*marginal_cost_bar*output_bar/hours_bar;
chi = wage_bar/(hours_bar^eta*consumption_bar);
nominal_rate_bar = gamma_bar*pi_bar/(beta*risk_premium_bar);
r_star = nominal_rate_bar;

model;
    // Gross technology growth is stationary even though its level accumulates.
    # Gamma = gamma_bar*exp(gamma_x);
    # Gamma_lead = gamma_bar*exp(gamma_x(+1));

    [name='capital_demand']
    rk = alpha*marginal_cost*Gamma*output/capital(-1);

    [name='labor_supply']
    wage = chi*hours^eta*consumption;

    [name='production']
    output = (capital(-1)/Gamma)^alpha*hours^(1-alpha);

    [name='labor_demand']
    wage = (1-alpha)*marginal_cost*output/hours;

    [name='capital_euler']
    1/consumption = beta/(Gamma_lead*consumption(+1))
        *(rk(+1)+1-delta);

    [name='resource_constraint']
    consumption+investment = output
        -phi_rot/2*(inflation/pi_bar-1)^2*output;

    [name='capital_accumulation']
    capital = (1-delta)/Gamma*capital(-1)+investment;

    [name='rotemberg_pricing']
    phi_rot*(inflation/pi_bar-1)*(inflation/pi_bar)
        = (1-theta)+theta*marginal_cost
        +phi_rot*beta*consumption/consumption(+1)
        *(inflation(+1)/pi_bar-1)*(inflation(+1)/pi_bar)
        *output(+1)/output;

    [name='bond_euler']
    1 = risk_premium*nominal_rate
        *beta*consumption/(Gamma_lead*consumption(+1)*inflation(+1));

    [name='monetary_policy']
    nominal_rate = r_star*(inflation/pi_bar)^phi_pi
        *(output/output_bar)^phi_y;

    [name='technology_growth']
    gamma_x = rho_x*gamma_x(-1)+sigma_x*eps_x;

    [name='risk_premium']
    risk_premium = (1-rho_s)*risk_premium_bar
        +rho_s*risk_premium(-1)+sigma_s*eps_s;
end;

steady_state_model;
    rk = rk_bar;
    wage = wage_bar;
    output = output_bar;
    hours = hours_bar;
    consumption = consumption_bar;
    investment = investment_bar;
    capital = capital_bar;
    inflation = pi_bar;
    nominal_rate = nominal_rate_bar;
    marginal_cost = marginal_cost_bar;
    risk_premium = risk_premium_bar;
    gamma_x = 0;
end;

shocks;
    var eps_x = 1;
    var eps_s = 1;
end;

resid;
steady;
check;
stoch_simul(order=1,irf=0,nograph,noprint);
