% Real Business Cycle Model
% Sample RBC Dynare file, not used anywhere here
% Variables
var y,z,k,n,c,i,w,r;

% Shocks
varexo eps;

% Parameters
parameters 	beta,delta,alpha,eta,gamma,zss,rho,sigma,chi;

% Parameters
% 	Subjective discount factor
beta = 0.995;
% 	Capital depreciation rate
delta = 0.025;
% 	Output elasticity
alpha = 1/3;
% 	Inverse labor supply elasticity
eta = 1;
% 	Coefficient of relative risk aversion
gamma = 1;
% 	Mean productivity
zss = 1.0;
% 	Productivity AC
rho = 0.9;
% 	Productivity shock SD
sigma = 1;

% Use Static RBC Model to solve for labor preference parameter
% 	Mean labor hours
nss = 1/3;
%   Consumption Euler Equation
rss = 1/beta + delta - 1;
%   Firm FOC Capital
yk = rss/alpha;
%   Production function
kss = nss*(zss/yk)^(1/(1-alpha));
%   Output
yss = kss*yk;
%	Wage rate
wss = (1-alpha)*yss/nss;
%   Investment
iss = delta*kss;
%   Aggregate resource constraint
css = yss - iss;
%	Labor preference parameter
chi = wss*css^(-gamma)*nss^(-eta);

% Dynamic RBC Model
model;
	% Production function
    y = z*k(-1)^alpha*n^(1-alpha);
	
	% Productivity process
    z = (1-rho)*zss + rho*z(-1) + sigma*eps;
	
	% Aggregate resource constraint
    c + i = w*n + r*k(-1);
	
	% Capital law of motion
    k = (1-delta)*k(-1) + i;
	
	% Capital demand
	r = alpha*y/k(-1);
	
	% Labor demand
	w = (1-alpha)*y/n;
	
	% Labor supply
	c^(-gamma)*w = chi*n^eta;
	
	% Household consumption equilibrium condition
    c^(-gamma) = beta*c(+1)^(-gamma)*(r(+1) + 1 - delta);
end;

% Set shock SD
shocks;
    var eps = 1;
end;

steady;

% First-order approximation
stoch_simul(order=1) z w n y c i;