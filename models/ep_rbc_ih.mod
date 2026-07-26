// Eusepi-Preston 13-equation infinite-horizon RBC representation.
// Source: the verified ep13_ih_re_linear.mod at tag ep-verification-v1.
// MATLAB replaces the RE present-value recursions with subjective forecasts.
var rk wage bond output hours caput capital mp investment rk_sum w_sum consumption gamma_x;
varexo eps_x;
parameters delta alpha rho_x gamma_bar sigma eps_H beta beta_tilda;
parameters delta_s R_tilda ik_ratio yk_ratio ck_ratio cy_ratio psi;
parameters eps_c eps_w chi c_c;

@#ifndef gamma_bar
    @#define gamma_bar = 1.0053140698457452
@#endif

delta=0.025; alpha=0.34; rho_x=0; gamma_bar=@{gamma_bar};
sigma=1; eps_H=0.0001; beta=0.99*gamma_bar^(sigma-1);
beta_tilda=beta*gamma_bar^(1-sigma);
delta_s=(1-delta)/gamma_bar;
R_tilda=beta_tilda^(-1)-delta_s;
ik_ratio=1-(1-delta)/gamma_bar;
yk_ratio=R_tilda/alpha;
ck_ratio=yk_ratio-ik_ratio;
cy_ratio=ck_ratio/yk_ratio;
psi=cy_ratio^(-1)*(1-alpha);
eps_c=ck_ratio+(eps_H-psi*(sigma-1)/sigma)^(-1)*R_tilda*(1-alpha)/alpha;
eps_w=(1+(eps_H-psi*(sigma-1)/sigma)^(-1))*R_tilda*(1-alpha)/alpha;
chi=psi*(1-sigma)/(sigma*eps_H+psi*(1-sigma));
c_c=(1-beta_tilda)*(1-chi)/eps_c;

model(linear);
 [name='technology'] gamma_x=rho_x*gamma_x(-1)+eps_x;
 [name='utilization'] caput=0;
 [name='externality'] mp=0;
 [name='production'] output=alpha*capital(-1)-alpha*gamma_x+(1-alpha)*hours+mp+alpha*caput;
 [name='labor_demand'] wage=output-hours;
 [name='capital_return'] rk=output+gamma_x-capital(-1)-caput;
 [name='resource_constraint'] output=cy_ratio*consumption+(1-cy_ratio)*investment;
 [name='capital_accumulation'] capital=ik_ratio*investment+delta_s*capital(-1)-delta_s*gamma_x;
 [name='labor_supply'] wage=consumption+(eps_H-psi*(sigma-1)/sigma)*hours;
 [name='bond_return'] bond=beta_tilda*R_tilda*rk(+1);
 // The auxiliaries store beta_tilda times the paper's discounted sums.
 [name='capital_pv'] rk_sum=beta_tilda*(rk(+1)+rk_sum(+1));
 [name='wage_pv'] w_sum=beta_tilda*(wage(+1)+w_sum(+1));
 [name='ih_consumption']
 consumption+psi*(1-sigma)/sigma*hours-c_c*R_tilda*rk
   +c_c/beta_tilda*gamma_x-c_c*(eps_w+chi*eps_c/(1-chi))*wage
 =(-R_tilda*(beta_tilda/sigma-c_c))*rk_sum
   +(c_c*(eps_w+eps_c*chi/(1-chi)))*w_sum
   +(c_c/beta_tilda)*capital(-1);
end;

initval;
 rk=0; wage=0; bond=0; output=0; hours=0; caput=0; capital=0;
 mp=0; investment=0; rk_sum=0; w_sum=0; consumption=0; gamma_x=0;
end;
shocks; var eps_x=1; end;
steady; check;
stoch_simul(order=1,irf=40,nograph) rk wage output hours consumption investment capital gamma_x;
