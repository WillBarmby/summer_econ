// Linear Eusepi-Preston benchmark with the one-period Euler decision rule.
// MATLAB supplies subjective forecasts and RLS updates outside Dynare.
var rk wage output mp hours consumption investment caput capital gamma_x;
varexo eps_x;
parameters beta delta alpha gamma_bar rho_x sigma eps_H;
parameters beta_tilda delta_s R_tilda ik_ratio yk_ratio ck_ratio cy_ratio psi;

delta=0.025; alpha=0.34; rho_x=0; gamma_bar=exp(0.0053);
sigma=1; eps_H=0.0001;
beta=0.99*gamma_bar^(sigma-1);
beta_tilda=beta*gamma_bar^(1-sigma);
delta_s=(1-delta)/gamma_bar;
R_tilda=beta_tilda^(-1)-delta_s;
ik_ratio=1-(1-delta)/gamma_bar;
yk_ratio=R_tilda/alpha;
ck_ratio=yk_ratio-ik_ratio;
cy_ratio=ck_ratio/yk_ratio;
psi=cy_ratio^(-1)*(1-alpha);

model(linear);
 [name='technology'] gamma_x=rho_x*gamma_x(-1)+eps_x;
 [name='utilization'] caput=0;
 [name='externality'] mp=0;
 [name='production'] output=alpha*capital(-1)-alpha*gamma_x
     +(1-alpha)*hours+mp+alpha*caput;
 [name='labor_demand'] wage=output-hours;
 [name='capital_return'] rk=output+gamma_x-capital(-1)-caput;
 [name='resource_constraint'] output=cy_ratio*consumption
     +(1-cy_ratio)*investment;
 [name='capital_accumulation'] capital=ik_ratio*investment
     +((1-delta)/gamma_bar)*capital(-1)
     -((1-delta)/gamma_bar)*gamma_x;
 [name='labor_supply'] wage=consumption
     +(eps_H-psi*(sigma-1)/sigma)*hours;
 [name='euler_consumption'] sigma*consumption+psi*(1-sigma)*hours
     =sigma*consumption(+1)+psi*(1-sigma)*hours(+1)
     -beta_tilda*R_tilda*rk(+1)+sigma*gamma_x(+1);
end;

initval;
 rk=0; wage=0; output=0; mp=0; hours=0; consumption=0;
 investment=0; caput=0; capital=0; gamma_x=0;
end;
shocks; var eps_x=1; end;
steady; check;
stoch_simul(order=1,irf=40,nograph) rk wage output hours consumption investment capital gamma_x;
