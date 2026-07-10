// Three-equation NK demonstration, explicitly linearized in deviations.
var output_gap inflation policy_rate natural_rate cost_push;
varexo eps_r eps_u eps_n;
parameters beta sigma kappa phi_pi phi_x rho_r rho_n rho_u;
beta=0.99; sigma=1; kappa=0.10; phi_pi=1.5; phi_x=0.125;
rho_r=0.8; rho_n=0.7; rho_u=0.5;

model(linear);
 [name='is_curve'] output_gap=output_gap(+1)-(policy_rate-inflation(+1)-natural_rate)/sigma;
 [name='phillips_curve'] inflation=beta*inflation(+1)+kappa*output_gap+cost_push;
 [name='policy_rule'] policy_rate=rho_r*policy_rate(-1)+(1-rho_r)*(phi_pi*inflation+phi_x*output_gap)+eps_r;
 [name='natural_rate'] natural_rate=rho_n*natural_rate(-1)+eps_n;
 [name='cost_push'] cost_push=rho_u*cost_push(-1)+eps_u;
end;

initval;
 output_gap=0; inflation=0; policy_rate=0; natural_rate=0; cost_push=0;
end;
shocks;
 var eps_r=1; var eps_u=1; var eps_n=1;
end;
steady;
check;
stoch_simul(order=1,irf=20,nograph) output_gap inflation policy_rate;
