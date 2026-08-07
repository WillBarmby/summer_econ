// Simplified nonlinear New Keynesian model with capital and Rotemberg pricing.
//
// Economic source
// ---------------
// This file implements Model 2 ("Baseline with Capital") in
// NK_Models/model/model_simple.tex. Gross inflation and interest rates and all
// real quantities are written in levels. The analytical steady state below is
// the expansion point for Dynare's first-order solution.
//
// Deliberate specializations relative to model_simple.tex
// -------------------------------------------------------
// 1. The monetary-policy rule uses its unconstrained Taylor-rule branch. The
//    source model writes max{1, Taylor rule}; the max operator and the ZLB are
//    omitted here. A local first-order perturbation around a nonbinding steady
//    state would not represent occasionally binding ZLB episodes. Restoring the
//    ZLB therefore requires a piecewise/nonlinear solution method, not only a
//    change to the equation below.
// 2. The policy output target is steady-state output, not flexible-price
//    (natural) output. The source discusses both alternatives.
// 3. The discount factor is constant and technology is the only shock.
// 4. The capital-adjustment-cost extension listed in the source calibration
//    table is not included; capital follows the displayed law of motion without
//    adjustment costs or Tobin's q.

// -----------------------------------------------------------------------------
// Variables
// -----------------------------------------------------------------------------

var
    rk
    wage
    output
    hours
    consumption
    investment
    capital
    inflation
    interest
    marginal_cost
    technology
;

varexo
    eps_technology
;

// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------

parameters
    beta
    eta
    chi
    delta
    alpha
    theta
    varphi
    inflation_bar
    phi_pi
    phi_y
    rho_technology
    technology_bar
;

parameters
    hours_bar
    marginal_cost_bar
    rk_bar
    ky_ratio
    output_bar
    capital_bar
    investment_bar
    consumption_bar
    wage_bar
    interest_bar
;

// -----------------------------------------------------------------------------
// Calibration
// -----------------------------------------------------------------------------

// Macro defaults preserve the source calibration while allowing named
// experiments to override selected parameters without rewriting this file.
@#ifndef rho_technology
    @#define rho_technology = 0.9
@#endif

beta             = 0.995;
eta              = 1/3;
delta            = 0.025;
alpha            = 0.33;
theta            = 6;
varphi           = 59.11;

inflation_bar    = 1.006;
phi_pi           = 1.5;
phi_y            = 0.1;

rho_technology   = @{rho_technology};
technology_bar   = 1;

// -----------------------------------------------------------------------------
// Calculated non-stochastic steady state
// -----------------------------------------------------------------------------

hours_bar = 1/3;

marginal_cost_bar = (theta - 1) / theta;

rk_bar = 1 / beta - 1 + delta;

ky_ratio = alpha * marginal_cost_bar / rk_bar;

output_bar =
    hours_bar
    * (technology_bar * ky_ratio^alpha)^(1 / (1-alpha));

capital_bar = ky_ratio * output_bar;

investment_bar = delta * capital_bar;

consumption_bar = output_bar - investment_bar;

wage_bar =
    (1-alpha)
    * marginal_cost_bar
    * output_bar / hours_bar;

chi =
    wage_bar
    / (hours_bar^eta * consumption_bar);

interest_bar = inflation_bar / beta;

// -----------------------------------------------------------------------------
// Model
// -----------------------------------------------------------------------------

model;

    [name = 'labor_supply']
    wage = chi * hours^eta * consumption;

    [name = 'bond_euler']
    1 = beta
        * interest
        * (consumption / consumption(+1))
        / inflation(+1);

    [name = 'capital_euler']
    1 / consumption
        = beta
        * (1 / consumption(+1))
        * (rk(+1) + 1 - delta);

    [name = 'production']
    output = technology
        * capital(-1)^alpha
        * hours^(1-alpha);

    [name = 'capital_demand']
    rk = alpha
        * marginal_cost
        * output / capital(-1);

    [name = 'labor_demand']
    wage = (1-alpha)
        * marginal_cost
        * output / hours;

    [name = 'price_setting']
    varphi
        * (inflation / inflation_bar - 1)
        * (inflation / inflation_bar)
      = (1-theta)
        + theta * marginal_cost
        + varphi
          * beta
          * (consumption / consumption(+1))
          * (inflation(+1) / inflation_bar - 1)
          * (inflation(+1) / inflation_bar)
          * (output(+1) / output);

    [name = 'resource_constraint']
    consumption + investment
      = output
        - (varphi / 2)
          * (inflation / inflation_bar - 1)^2
          * output;

    [name = 'capital_accumulation']
    capital = (1-delta) * capital(-1) + investment;

    [name = 'monetary_policy']
    // Unconstrained branch of the source's max{1, Taylor rule}; see header.
    interest
      = interest_bar
        * (inflation / inflation_bar)^phi_pi
        * (output / output_bar)^phi_y;

    [name = 'technology']
    technology
      = technology_bar
        * (technology(-1) / technology_bar)^rho_technology
        * exp(eps_technology);

end;

// -----------------------------------------------------------------------------
// Analytical steady state supplied to Dynare
// -----------------------------------------------------------------------------

steady_state_model;

    consumption   = consumption_bar;
    hours         = hours_bar;
    investment    = investment_bar;
    capital       = capital_bar;
    output        = output_bar;

    wage          = wage_bar;
    rk            = rk_bar;
    marginal_cost = marginal_cost_bar;

    inflation     = inflation_bar;
    interest      = interest_bar;
    technology    = technology_bar;

end;

// -----------------------------------------------------------------------------
// Diagnostics
// -----------------------------------------------------------------------------

steady;
resid;
check;
model_diagnostics;

// -----------------------------------------------------------------------------
// Shock calibration
// -----------------------------------------------------------------------------

shocks;
    var eps_technology = 0.0025^2;
end;

// -----------------------------------------------------------------------------
// First-order RE solution and IRFs
// -----------------------------------------------------------------------------

stoch_simul(
    order = 1,
    irf = 40,
    nograph
)
    output
    consumption
    investment
    capital
    hours
    inflation
    interest
    wage
    rk
    marginal_cost
;


write_latex_original_model(write_equation_tags);
write_latex_dynamic_model(write_equation_tags);
write_latex_static_model(write_equation_tags);
