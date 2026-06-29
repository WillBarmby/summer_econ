


%%% THIS FILE UPLOADS AND ELABORATES THE DATA FOR CALIBRATION
%%% THIS IS FOR THE MODEL WITH NOMINAL RIGIDITIES

%function [data_growth,data_level,time]= data_fun(bcm)
     
     
  
     
%% comment if use as a function        
   clear all;clc;
   
 bcm = 0;

% sample =1;


%% ACEL DATA from DLX
 
 nominal_gdp = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'B7:B250');
 
 nominal_gdp = nominal_gdp';
 
 Real_gdp = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'C7:C250');
 Real_gdp = Real_gdp';
 
 price_index = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'D7:D250');
 price_index = price_index';
 
 nominal_consumption = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'E7:E250');
 nominal_consumption = nominal_consumption';
 
 nominal_private_consumption = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'S7:S250');
 nominal_private_consumption = nominal_private_consumption';
 
 nominal_investment = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'F7:F250');
 nominal_investment = nominal_investment';
 
 non_farm_bus_hours = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'H7:H250');
 non_farm_bus_hours = non_farm_bus_hours';
 
 nominal_wages = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'I7:I250');
 nominal_wages = nominal_wages';  %% from NFB sector (hourly wage)
 
 nominal_wages_1 = xlsread('compensation_employees', 'WASCUR', 'B18:B261');
 nominal_wages_1 = nominal_wages_1'; %% NIPA ACCOUNTS (total wages)

 pop_16 = xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'J7:J250');
 pop_16 = pop_16';
 
 weekly_hours = xlsread('hours_and_employment', 'Sheet1', 'D102:D280');
 weekly_hours = weekly_hours';
 
 employment = xlsread('employment_DLX', 'Sheet1', 'B7:B250');
 employment = employment';
 
 caput =  xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'K7:K250'); %% DATA ALREADY IN LOGS!
 caput = caput';
 
 tot_hours_ramey = xlsread('Francis_Ramey_Hours_Data_Public', 'Francis-Ramey Hours Data', 'B10:B249');
 tot_hours_ramey = tot_hours_ramey';
 
 pop22_64 = xlsread('Francis_Ramey_Hours_Data_Public', 'Francis-Ramey Hours Data', 'T10:T249');
 pop22_64 =pop22_64';
 
 adj_pop = xlsread('Francis_Ramey_Hours_Data_Public', 'Francis-Ramey Hours Data', 'O10:O249');
 adj_pop = adj_pop';
 
%% CREATE VARIABLES
 
 real_percapita_cons = log((nominal_consumption(1:end-4)./price_index(1:end-4))./pop_16(1:end-4));
 real_private_cons = log((nominal_private_consumption(1:end-4)./price_index(1:end-4))./pop_16(1:end-4));
 real_percapita_inv = log((nominal_investment(1:end-4)./price_index(1:end-4))./pop_16(1:end-4));
 real_percapita_gdp = log(Real_gdp(1:end-4)./pop_16(1:end-4));
 hours_percapita_NBS = log(non_farm_bus_hours(1:end-4)./(pop_16(1:end-4)));
 
 hours_percapita_ramey = log(tot_hours_ramey./adj_pop);
 hours_percapita_22 = log(tot_hours_ramey./pop22_64);
 employment_rate_22 = log(employment(1:end-4)./(pop22_64));
 
 employment_rate = log(employment(1:end-4)./(pop_16(1:end-4)));
 
 real_private_cons_22 = log((nominal_private_consumption(1:end-4)./price_index(1:end-4))./pop22_64);
 real_percapita_inv_22 = log((nominal_investment(1:end-4)./price_index(1:end-4))./pop22_64);
 real_percapita_gdp_22 = log(Real_gdp(1:end-4)./pop22_64);
 
 productivity_1 = log(Real_gdp(1:end-4)./tot_hours_ramey);
 productivity_0 = log(Real_gdp(1:end-4)./non_farm_bus_hours(1:end-4));
 
 real_wage = log(nominal_wages(1:end-4)./price_index(1:end-4));
 real_wage_22 = log((nominal_wages_1(1:end-4)./price_index(1:end-4))./tot_hours_ramey);


if bcm == 0

%% Ramey adj. series
data1 = [real_percapita_gdp_22;real_private_cons_22;real_percapita_inv_22;productivity_1];

data_growth = data1(:,2:end)-data1(:,1:end-1); % one observation missing

data_level = [data1(:,2:end);hours_percapita_22(2:end)];

var_growth1 = [data_growth;hours_percapita_22(2:end)-hours_percapita_22(1:end-1)];

else
    
   
%% Benchmark

data1 = [real_percapita_gdp;real_private_cons;real_percapita_inv;productivity_0;real_wage];

data_growth = data1(:,2:end)-data1(:,1:end-1); % one observation missing

data_level = [data1(:,2:end);hours_percapita_NBS(2:end)];

end

time = 1948.25:0.25:2007.75; %% (counting the missing observation)


%% STATISTICS


 % LIST of VARS: {'y','c','i','Pr','h'}
 c_i = 2; i_i = 3; y_i = 1; Pr_i = 4;  h_i = 5;
 
 
  %% Compute hp filtered series

%% Sample: 1955Q3:2007Q4

hp_data_sample = data_level(:,29:end)';
 
[y_sample_trend,desvabs] = hpfilter(hp_data_sample,1600);

var_level_detr = hp_data_sample'-y_sample_trend';

%% Compute bc statistics

  % Levels 
  
  STD_var_level_detr = std(var_level_detr,0,2);
  

rowMat = 1:size(var_level_detr,1);

maxT = 10;


[auto cross] = autoCrossCorrel(var_level_detr, rowMat, maxT, {'y','c','i','Pr','h'}); 


Moments_level_detr = [STD_var_level_detr(y_i)
                     STD_var_level_detr(c_i)/STD_var_level_detr(y_i)
                     STD_var_level_detr(i_i)/STD_var_level_detr(y_i)
                     STD_var_level_detr(h_i)/STD_var_level_detr(y_i)
                     STD_var_level_detr(Pr_i)/STD_var_level_detr(y_i)
                     cross{1+y_i,1+c_i}
                     cross{1+y_i,1+i_i}
                     cross{1+y_i,1+h_i}
                     cross{1+y_i,1+Pr_i}
                     cross{1+Pr_i,1+h_i}];

disp('HP Filtered data: Relative Std Dev and Correlation')

disp(Moments_level_detr)


  %% Compute statistics in growth rates
  
  var_growth = var_growth1(:,29:end);
  
   STD_var_growth = std(var_growth,0,2);
  

rowMat = 1:size(var_growth,1);

maxT = 10;


[auto cross] = autoCrossCorrel(var_growth, rowMat, maxT, {'y','c','i','Pr','h'}); 


Moments_growth = [   400*STD_var_growth(y_i)
                     STD_var_growth(c_i)/STD_var_growth(y_i)
                     STD_var_growth(i_i)/STD_var_growth(y_i)
                     STD_var_growth(h_i)/STD_var_growth(y_i)
                     STD_var_growth(Pr_i)/STD_var_growth(y_i)
                    
                     cross{1+y_i,1+c_i}
                     cross{1+y_i,1+i_i}
                     cross{1+y_i,1+h_i}
                     cross{1+y_i,1+Pr_i}
                     cross{1+Pr_i,1+h_i}
                     
                     
                     auto{2,1+c_i}
                     auto{2,1+i_i}
                     auto{2,1+y_i}
                     auto{2,1+h_i}
                     auto{2,1+Pr_i}
                     ];
                 
  
                     
                     
   disp('Data in growth rates: Relative Std Dev, Correlation and Autocorrelation')

disp(Moments_growth)


  