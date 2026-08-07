var y;
varexo eps;

parameters rho;
rho = 0.5;

model(linear);
    y = rho*y(-1) + 0.25*y(+1) + eps;
end;

initval;
    y = 0;
end;

steady;
check;
stoch_simul(order=1,irf=0,nograph,noprint);
