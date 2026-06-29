
% clear all; %clc

%% This function computes the distributions of all coefficients in the model
%% ADD MORE EXPLANATION

function [f_vec,x_vec,f_n_vec,mu_vec,sigma_vec] = distr_fun(n_eq,n_x,n_c,ini_sample,COEFF_STORE)



%% if not used as a function

%% Parameters (model specific)
%load COEFF_STORE_mat3
% n_eq = 3; n_x = 5; n_c = 0;
% ini_sample = 1000;


%% Defines matrices

    length_vec = size(COEFF_STORE{1},2)-ini_sample+1;
     
     for eq_ctn = 1:n_eq
         
         f_vec{eq_ctn} = zeros(n_x+n_c,100);
         
           f_n_vec{eq_ctn} = zeros(n_x+n_c,100);
           
             mu_vec{eq_ctn} = zeros(n_x+n_c,1);
             
             sigma_vec{eq_ctn} = zeros(n_x+n_c,1);
             
               f_vec{eq_ctn} = zeros(n_x+n_c,100);
               
               x_vec{eq_ctn} = zeros(n_x+n_c,100);
     end
     
     
     %% NOTE: to see why the number 100, check the command ksdensity



 %% Creating distributions
    
     for eq_ctn = 1:n_eq
         
         for n_x_ctn = 1:n_x+n_c
 
[f, f_n, x,mu,sigma] = ...
    beliefs_distribution(COEFF_STORE{eq_ctn}(n_x_ctn,ini_sample:end));

% mu
% sigma
% length(x)


%% Creates matrices containing the distributions
f_vec{eq_ctn}(n_x_ctn,1:end) = f;

x_vec{eq_ctn}(n_x_ctn,1:end) = x;

f_n_vec{eq_ctn}(n_x_ctn,1:end) = f_n;

mu_vec{eq_ctn}(n_x_ctn) = mu; 

sigma_vec{eq_ctn}(n_x_ctn) = sigma; 

         end 
     end
     
     
     
     
     
     
     
