
clear all; %clc

 global epsZ 
 
 
 Sim_length = 5162;
 
 n_sample = 5000;
 
  diary('results_RBC_162')
 
 for jj = 1:n_sample
     
 epsZ = randn(1,Sim_length);
 
 not=1;
 

% [Moments_level_detr,Moments_growth,Auto_corr_growth,...
%     Output_growth_auto,corr_w1,corr_w4,corr_rk1,corr_rk4,corr_R1,corr_R3,...
%     acorr_w1,acorr_w4,acorr_rk1,acorr_rk4,acorr_R1,acorr_R3] = bus_cycle_stats_fun(not);


[Moments_level_detr,Moments_growth,Auto_corr_growth,...
    Output_growth_auto,corr_w1,corr_w2,corr_w3,corr_w4,...
    corr_rk1,corr_rk2,corr_rk3,corr_rk4,corr_R1,corr_R3,...
    acorr_w1,acorr_w2,acorr_w3,acorr_w4,...
    acorr_rk1,acorr_rk2,acorr_rk3,acorr_rk4,acorr_R1,acorr_R3,...
    STD_var_wrk,w_auto,rk_auto] = bus_cycle_stats_fun(not);

disp(jj)


var_moments_level_mat(:,jj) = Moments_level_detr;

var_moments_growth_mat(:,jj) = Moments_growth;

Auto_corr_growth_mat(:,jj) = Auto_corr_growth;

Output_growth_auto_mat(:,jj) = Output_growth_auto;

STD_var_wrk_mat(:,jj) = STD_var_wrk;

w_auto_mat(:,jj) = w_auto;

rk_auto_mat(:,jj) = rk_auto;

corr_R1_mat(:,jj) = corr_R1; 

corr_R3_mat(:,jj) = corr_R3;


corr_w1_mat(:,jj) = corr_w1;

corr_w2_mat(:,jj) = corr_w2;

corr_w3_mat(:,jj) = corr_w3;

corr_w4_mat(:,jj) = corr_w4;


corr_rk1_mat(:,jj) = corr_rk1;

corr_rk2_mat(:,jj) = corr_rk2;

corr_rk3_mat(:,jj) = corr_rk3;

corr_rk4_mat(:,jj) = corr_rk4;


acorr_R1_mat(:,jj) = acorr_R1; 

acorr_R3_mat(:,jj) = acorr_R3;


acorr_w1_mat(:,jj) = acorr_w1;

acorr_w2_mat(:,jj) = acorr_w2;

acorr_w3_mat(:,jj) = acorr_w3;

acorr_w4_mat(:,jj) = acorr_w4;


acorr_rk1_mat(:,jj) = acorr_rk1;

acorr_rk2_mat(:,jj) = acorr_rk2;

acorr_rk3_mat(:,jj) = acorr_rk3;

acorr_rk4_mat(:,jj) = acorr_rk4;

 end
 

 
 %% Statistics
 
 mean_L = mean(var_moments_level_mat')';
 
 std_L = std(var_moments_level_mat')';

  mean_G = mean(var_moments_growth_mat')';
 
 std_G = std(var_moments_growth_mat')';

 mean_wrk = mean(STD_var_wrk_mat')';
 
 std_wrk = std(STD_var_wrk_mat')';
 
 
 
 mean_autog = mean(Auto_corr_growth_mat')';

 std_autog = std(Auto_corr_growth_mat')';

 mean_autogy = mean(Output_growth_auto_mat')';

 std_autogy = std(Output_growth_auto_mat')';
 
mean_w_auto = mean(w_auto_mat')';

 std_w_auto = std(w_auto_mat')';

mean_rk_auto = mean(rk_auto_mat')';

 std_rk_auto = std(rk_auto_mat')';
 
 
 mean_R1 = mean(corr_R1_mat);
 
 std_R1 = std(corr_R1_mat);
 
  mean_R3 = mean(corr_R3_mat);
 
 std_R3 = std(corr_R3_mat);
 
 
   mean_w1 = mean(corr_w1_mat);
 
 std_w1 = std(corr_w1_mat);
 
 mean_w2 = mean(corr_w2_mat);
 
 std_w2 = std(corr_w2_mat);
 
 mean_w3 = mean(corr_w3_mat);
 
 std_w3 = std(corr_w3_mat);
 
 mean_w4 = mean(corr_w4_mat);
 
 std_w4 = std(corr_w4_mat);
 
 
 mean_rk1 = mean(corr_rk1_mat);
 
 std_rk1 = std(corr_rk1_mat);
 
 mean_rk2 = mean(corr_rk2_mat);
 
 std_rk2 = std(corr_rk2_mat);
 
 mean_rk3 = mean(corr_rk3_mat);
 
 std_rk3 = std(corr_rk3_mat);
 
 mean_rk4 = mean(corr_rk4_mat);
 
 std_rk4 = std(corr_rk4_mat);
 
 
 mean_aw1 = mean(acorr_w1_mat);
 
 std_aw1 = std(acorr_w1_mat);

 mean_aw2 = mean(acorr_w2_mat);
 
 std_aw2 = std(acorr_w2_mat);
 
 mean_aw3 = mean(acorr_w3_mat);
 
 std_aw3 = std(acorr_w3_mat);
 
 mean_aw4 = mean(acorr_w4_mat);
 
 std_aw4 = std(acorr_w4_mat);
 
 
 mean_ark1 = mean(acorr_rk1_mat);
 
 std_ark1 = std(acorr_rk1_mat);
 
 mean_ark2 = mean(acorr_rk2_mat);
 
 std_ark2 = std(acorr_rk2_mat);
 
 mean_ark3 = mean(acorr_rk3_mat);
 
 std_ark3 = std(acorr_rk3_mat);
 
 mean_ark4 = mean(acorr_rk4_mat);
 
 std_ark4 = std(acorr_rk4_mat);
 
 diary off



save results_RBC_162b 
 