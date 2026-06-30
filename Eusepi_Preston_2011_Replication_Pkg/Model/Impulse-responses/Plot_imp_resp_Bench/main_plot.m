%% PLOTS IMPULSE RESPONSES
clear all


plot_dir = fileparts(mfilename('fullpath'));
imp_resp_dir = fullfile(plot_dir, '..');

load(fullfile(imp_resp_dir, 'COEFF_STORE_impresp_mat_learn_bench2.mat'), ...
    'imp_resp_vec_RBC_learn_bench2');

imp_resp_vec_L = imp_resp_vec_RBC_learn_bench2;

% load data_imp_L
% imp_resp_vec_L = imp_resp_vec_RBC_learn_bench;



%% select percentile
band_up = .15*size(imp_resp_vec_L{1},1);

band_down = (1-0.15)*size(imp_resp_vec_L{1},1);




%% Create median impulse responses and bands


n_impulse_resp = 12;

T_imp = 64; %% T_imp-1 is the number of periods in the IR


%% Median impulse responses

for j1 =1:n_impulse_resp
    
    for j2 = 1:T_imp-1
    
median_imp_resp_vec_L{j1}(j2) = median(imp_resp_vec_L{j1}(:,j2));

end

end



%% Compute bands


for j1 =1:n_impulse_resp

  for j2 = 1:T_imp-1

vec_sort = sort(imp_resp_vec_L{j1}(:,j2));

low_band_L{j1}(j2) = vec_sort(band_down);  %%$work in progress (define percentile?)...

up_band_L{j1}(j2) =  vec_sort(band_up);

  end 

end

load(fullfile(imp_resp_dir, 'COEFF_STORE_impresp_mat_ree_bench.mat'), ...
    'imp_resp_vec_RBC_ree_bench');




imp_resp_vec_R = imp_resp_vec_RBC_ree_bench;



%% select percentile
band_up = .15*size(imp_resp_vec_R{1},1);

band_down = (1-0.15)*size(imp_resp_vec_R{1},1);




%% Create median impulse responses and bands

%% Median impulse responses

for j1 =1:n_impulse_resp
    
    for j2 = 1:T_imp-1
    
median_imp_resp_vec_R{j1}(j2) = median(imp_resp_vec_R{j1}(:,j2));

end

end



%% Compute bands


for j1 =1:n_impulse_resp

  for j2 = 1:T_imp-1

vec_sort = sort(imp_resp_vec_R{j1}(:,j2));

low_band_R{j1}(j2) = vec_sort(band_down);  %%$work in progress (define percentile?)...

up_band_R{j1}(j2) =  vec_sort(band_up);

  end 

end

%% Plot

w = 1;
c  =2;
iv  =3;
y  =4;
b  =5;
h =6;
rk_sum =7;
w_sum =8;
Exprk1 = 9;
Expw1 = 10;
ExpR20 = 11;
Exp40 = 12;

NIR = 40;


%% MAIN FIGURE

figure(1);

 ng = 'quantities';
 
 subplot(2,2,1,'align') % CONSUMPTION


plot(1:NIR,median_imp_resp_vec_L{c}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_R{c}(1,1:NIR),'k--',1:NIR,low_band_L{c}(1:NIR),'k:',1:NIR,up_band_L{c}(1:NIR),'k:','linewidth',2);
%plot(1:NIR,4*median_imp_resp_vec_L{b}(1,1:NIR),'k-',1:NIR,4*median_imp_resp_vec_R{b}(1,1:NIR),'k--',1:NIR,4*low_band_L{b}(1:NIR),'k:',1:NIR,4*up_band_L{b}(1:NIR),'k:','linewidth',2);
  
 title('Consumption')

 axis([0 40 0.2 1.3]);
  xlabel('Quarters');ylabel('%dev. from un-shocked BGP','FontSize',8);
  
  
  subplot(2,2,2,'align') % OUTPUT


plot(1:NIR,median_imp_resp_vec_L{y}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_R{y}(1,1:NIR),'k--',1:NIR,low_band_L{y}(1:NIR),'k:',1:NIR,up_band_L{y}(1:NIR),'k:','linewidth',2);
  
 title('Output')

  xlabel('Quarters');%ylabel('%dev. from un-shocked BGP');

 
  subplot(2,2,3,'align') % INVESTMENT


plot(1:NIR,median_imp_resp_vec_L{iv}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_R{iv}(1,1:NIR),'k--',1:NIR,low_band_L{iv}(1:NIR),'k:',1:NIR,up_band_L{iv}(1:NIR),'k:','linewidth',2);
  
 title('Investment')
axis([0 40 0.5 5.0]);
  xlabel('Quarters');ylabel('%dev. from un-shocked BGP','FontSize',8); 
  
  
   subplot(2,2,4,'align') % HOURS


plot(1:NIR,median_imp_resp_vec_L{h}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_R{h}(1,1:NIR),'k--',1:NIR,low_band_L{h}(1:NIR),'k:',1:NIR,up_band_L{h}(1:NIR),'k:','linewidth',2);
  
 title('hours')

  xlabel('Quarters');%ylabel('%dev. from un-shocked BGP'); 
  
 
  % figure(1);     print(char(strcat(ng,'.eps')),'-depsc2');   print(char(strcat(ng,'.pdf')),'-dpdf');   

%% EXPECTED SUMS

figure(2);

 ng = 'expected sums';
 
 subplot(2,1,1) % RKSUM


plot(1:NIR,median_imp_resp_vec_L{rk_sum}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_R{rk_sum}(1,1:NIR),'k--',1:NIR,low_band_L{rk_sum}(1:NIR),'k:',1:NIR,up_band_L{rk_sum}(1:NIR),'k:','linewidth',2);
  
 title('E_t\Sigma^\infty_T_=_t\beta^T^-^t^+^1R^k_T_+_1')

  xlabel('Quarters');ylabel('% dev. from SS');
  
  
  subplot(2,1,2) % WSUM


plot(1:NIR,median_imp_resp_vec_L{w_sum}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_R{w_sum}(1,1:NIR),'k--',1:NIR,low_band_L{w_sum}(1:NIR),'k:',1:NIR,up_band_L{w_sum}(1:NIR),'k:','linewidth',2);
  
 title('E_t\Sigma^\infty_T_=_t\beta^T^-^t^+^1w_T_+_1')

  xlabel('Quarters');ylabel('% dev. from SS');
  
  % figure(2);     print(char(strcat(ng,'.eps')),'-depsc2');   print(char(strcat(ng,'.pdf')),'-dpdf');   

%% FORECAST ERRORS, OUTPUT, AND FORECAST PATH

load path_impulses %% these are produced in the "forecast path" folder

Rkpath_learn = exp_vec_rk2;

RKpath_REE = exp_vec_rk2_R;

figure(3);

 ng = 'nonsep_impresp3';
 
 subplot(2,1,1) % Forecast errors and output


plot(1:NIR,median_imp_resp_vec_L{Exprk1}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_L{y}(1,1:NIR)-median_imp_resp_vec_R{y}(1,1:NIR),'k--',1:NIR,low_band_L{Exprk1}(1:NIR),'k:',1:NIR,up_band_L{Exprk1}(1:NIR),'k:','linewidth',2);
  
 title('R^k Forecast Errors and Y^L^E-Y^R^E')

  xlabel('Quarters');ylabel('% dev. from SS');
  
  
  subplot(2,1,2) % Rk forecast path

 ax = [1;5;10;20;30;40;50;100]; 

plot(ax,Rkpath_learn,'k-',ax,RKpath_REE,'k--','linewidth',2);
  
 title('R^k Forecast Path')

 axis([0 100 -0.05 0.9]);
 
  xlabel('Forecast Horizon');ylabel('% dev. from SS');
  

 %figure(3);     print(char(strcat(ng,'.eps')),'-depsc2');   print(char(strcat(ng,'.pdf')),'-dpdf');   
 
 figure(4)
 
plot(1:NIR,median_imp_resp_vec_L{Exp40}(1,1:NIR),'k-',1:NIR,median_imp_resp_vec_R{Exp40}(1,1:NIR),'k--',1:NIR,low_band_L{Exp40}(1:NIR),'k:',1:NIR,up_band_L{Exp40}(1:NIR),'k:','linewidth',2);
  
 title('R^k 10-Years-Ahead Forecast')
axis([0 40 -0.025 0.1]);
  xlabel('Quarters');ylabel('% dev. from SS');

