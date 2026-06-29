

%%%% COMPUTE BUSINESS CYCLE STATISTICS
%clear all

function [Model_moments_std,Model_moments_auto,FErk_corr] =  BC_statistics_adj_cost_model(f)

global zeta


        
  

%% Model's paramters

    
x = [ 1
   1
   -4.5633
  1
 1
  1
  1
     ];

param = zeros(14,1);

zeta = 0.57; 

     param(1) = 1.005; param(2) = 1; param(3) = 1000.0004^(-1)*param(2)/zeta; param(4) = 0; 
     param(5) = 0.0; param(6) = 1000.006; param(7) = 0.999;
     param(8) = 0.99; param(9) = 0.85; param(10) = 0.9999; param(11) = 0.95; param(12) = 0.0005;
     param(13) = 0; param(14) = 0.0053; 
gamma = exp(param(14));
 
 std_vec_s = [exp(x(1));exp(x(2));exp(x(3));exp(-30);exp(x(4));exp(x(5));exp(x(6));exp(x(7))];
 
 std_mat_s = diag(std_vec_s);
 
 
 
%% Model simulation
 


[A,B,C,NY,NX,NK] = external_habit_model_new(param);

[Br,Cr,Lr,NF] = redsf(A,B,C,NY,NX,NK);
 
[D,F1,G,H1] = soldsf(Br,Cr,Lr,NY,NX,NK,NF);
 
 D = real(D); F1 = real(F1); G = real(G); H1 = real(H1);
 
 
 F = [zeros(NY-NK,NY-NK) D(1:NY-NK,:)
      zeros(NK,NY-NK)    G];
 
  Sc = [F1(1:NY-NK,:)
        H1(1:NK,:)];
    
  %% Model simulation

  sl = 1110;
  
 epsZ1 = randn(8,sl); 
 
 epsZ = zeros(size(epsZ1,1),size(epsZ1,2));
 
 % shock selector: list of shocks
n_i = 1;

n_g = 2;

n_rw = 3;

n_p = 4;

n_a0 = 5;

n_a1 = 6;

n_a2 = 7;

n_a3 = 8; 
 
s_s = zeros(8,1);

%% I_shock

%s_s(n_i) = 1;

%% News shocks

%s_s(n_a0) = ones(1,1);

%% G_shock

%s_s(n_g) = 1;

%% RW-shock

s_s(n_rw) = 1;

%% ALL

% s_s = ones(8,1);


for j = 1:8
    
  epsZ(j,:) = s_s(j).*epsZ1(j,:);

end


%  save shocks_mat epsZ
% 
%  load shocks_mat

 ss_vec = std_mat_s*epsZ;
 
 Y_var = zeros(size(F,2),sl);
 
 error = zeros(1,sl);
 
for j = 2:sl


    
    
    Y_var(:,j) = F*Y_var(:,j-1)+Sc*ss_vec(:,j);
 
% if j>4
%     fcst =F^4*Y_var(:,j-4);
% error(j) = Y_var(1,j)-fcst(1);
% end


    fcst =F*Y_var(:,j-1);
error(j) = Y_var(1,j)-fcst(1);
end




%% Compute nonstationary series in levels
%% consumption growth, investment growth,  output and productivity growth

y_obs_vec = zeros(4,size(Y_var,2));

y_obs_vec(:,1) = [Y_var(15:16,1);Y_var(18:19,1)]+log(gamma);  
 
 
 for j = 2:size(Y_var,2)
 
 y_obs_vec(:,j) = [Y_var(15:16,j);Y_var(18:19,j)]+log(gamma)+y_obs_vec(:,j-1);
     
 end
 
 %{'c','i','y','pr','e','h','N','caput'});
 y_obsl = [y_obs_vec(1:4,1:end);Y_var(3,1:end);Y_var(9,1:end);Y_var(5,1:end);Y_var(8,1:end)];

 

%% Compute hp filtered series


hp_data_sample = y_obsl(:,1001:end)';

 
 [y_sample_trend,desvabs] = hpfilter(hp_data_sample,1600);
 

 
  data_sampled = hp_data_sample'-y_sample_trend';
     
    
    std_data_full = std(data_sampled,0,2);

    variance = var(data_sampled,0,2);
    
%% Compute bc statistics

rowMat = 1:size(data_sampled,1);

maxT = 10;

c_i = 1; i_i = 2; y_i = 3; pr_i = 4; e_i = 5; h_i = 6; N_i = 7; cpt_i = 8;

[auto cross] = autoCrossCorrel(data_sampled, rowMat, maxT, {'c','i','y','pr','e','h','N','caput'}); 


Model_moments_std = [100*std_data_full(y_i)
                     std_data_full(c_i)/std_data_full(y_i)
                     std_data_full(i_i)/std_data_full(y_i)
                     std_data_full(N_i)/std_data_full(y_i)
                     std_data_full(pr_i)/std_data_full(y_i)
                     std_data_full(pr_i)/std_data_full(N_i)
                     std_data_full(cpt_i)/std_data_full(y_i)
                     std_data_full(e_i)/std_data_full(N_i)];
                 
                 
%  Model_moments_corr = [cross{1+y_i,1+c_i}
%                        cross{1+y_i,1+i_i}
%                        cross{1+y_i,1+N_i}
%                        cross{1+y_i,1+pr_i}
%                        cross{1+N_i,1+pr_i}
%                        cross{1+y_i,1+cpt_i}
%                        cross{1+e_i,1+h_i}];   

% Growth rates

y_growth = hp_data_sample(2:end,1:4)'-hp_data_sample(1:end-1,1:4)';

rowMat = 1:size(y_growth,1);

[auto1 cross1] = autoCrossCorrel(y_growth , rowMat, maxT, {'c','i','y','pr'}); 

Model_moments_auto = [auto1{2,1+c_i}
                       auto1{2,1+y_i}
                       auto1{2,1+i_i}];
                   
FErk_corr = corr(error(2:end)',error(1:end-1)');

