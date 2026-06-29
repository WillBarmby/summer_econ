


function [f, f_n,x,mu,sigma] = beliefs_distribution(variable)


%% Nonparametric distribution
[f,x] = ksdensity(variable);

%% Estimates the normal distribution
[mu,sigma,muci,sci] = normfit(variable);

%% Simulates normal
[f_n] = Plot_Normal(mu,sigma,x);


