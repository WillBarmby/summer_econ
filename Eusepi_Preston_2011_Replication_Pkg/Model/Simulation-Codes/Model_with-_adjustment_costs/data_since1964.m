


%%% THIS FILE UPLOADS AND ELABORATES THE DATA FOR CALIBRATION
%%% THIS IS FOR THE MODEL WITH NOMINAL RIGIDITIES

function [data,time]= data_since1964(bcm)
     
     
  
     
%% comment if use as a function        
%    clear all;clc;
%    
 %  bcm = 1;



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
 
%  weekly_hours = xlsread('hours_and_employment', 'Sheet1', 'D102:D280');
%  weekly_hours = weekly_hours';
%  
%  employment = xlsread('employment_DLX', 'Sheet1', 'B7:B250');
%  employment = employment';
 
 caput =  xlsread('data_file_ACEF_03_09', 'ACEL_Data', 'K7:K250'); %% DATA ALREADY IN LOGS!
 caput = caput';
 
 tot_hours_ramey = xlsread('Francis_Ramey_Hours_Data_Public', 'Francis-Ramey Hours Data', 'B10:B249');
 tot_hours_ramey = tot_hours_ramey';
 
 pop22_64 = xlsread('Francis_Ramey_Hours_Data_Public', 'Francis-Ramey Hours Data', 'T10:T249');
 pop22_64 =pop22_64';
 
 adj_pop = xlsread('Francis_Ramey_Hours_Data_Public', 'Francis-Ramey Hours Data', 'O10:O249');
 adj_pop = adj_pop';
 
weekly_hours = xlsread('employment2', 'Sheet1', 'B5:B248');
weekly_hours = weekly_hours';

employment = xlsread('employment2', 'Sheet1', 'c5:c248');
employment = employment';

total_hoursNFB = xlsread('employment2', 'Sheet1', 'D5:D248');
total_hoursNFB = total_hoursNFB'; 

empl_pop_ratio =  xlsread('employment_pop_ratio', 'Sheet1', 'D11:D254');
empl_pop_ratio = empl_pop_ratio';

employmentrate = xlsread('Hall_and_unemployment', 'Sheet2', 'C2:C245');

employmentrate = employmentrate';

%% CREATE VARIABLES
 
 real_percapita_cons = log((nominal_consumption(1:end-4)./price_index(1:end-4))./pop_16(1:end-4));
 real_private_cons = log((nominal_private_consumption(1:end-4)./price_index(1:end-4))./pop_16(1:end-4));
 real_percapita_inv = log((nominal_investment(1:end-4)./price_index(1:end-4))./pop_16(1:end-4));
 real_percapita_gdp = log(Real_gdp(1:end-4)./pop_16(1:end-4));
 hours_percapita_NBS = log(total_hoursNFB(1:end-4)./(pop_16(1:end-4)));
 
 hours_percapita_NBS_22 = log(total_hoursNFB(1:end-4)./(pop22_64));
 
 hours_percapita_ramey = log(tot_hours_ramey./adj_pop);
 hours_percapita_22 = log(tot_hours_ramey./pop22_64);
 
 employment_rate_22 = log(employment(1:end-4)./(pop22_64));
 
 employment_rate = log(employment(1:end-4)./(pop_16(1:end-4)));
 
 
 employment_rate2 = log(empl_pop_ratio(1:end-4));
 
 employment_rate3 = log(employmentrate(1:end-4));
 
 real_private_cons_22 = log((nominal_private_consumption(1:end-4)./price_index(1:end-4))./pop22_64);
 real_percapita_inv_22 = log((nominal_investment(1:end-4)./price_index(1:end-4))./pop22_64);
 real_percapita_gdp_22 = log(Real_gdp(1:end-4)./pop22_64);
 
 productivity_1 = log(Real_gdp(1:end-4)./tot_hours_ramey);
 productivity_0 = log(Real_gdp(1:end-4)./non_farm_bus_hours(1:end-4));
 
 real_wage = log(nominal_wages(1:end-4)./price_index(1:end-4));
 real_wage_22 = log((nominal_wages_1(1:end-4)./price_index(1:end-4))./tot_hours_ramey);


if bcm == 0

%% {'c','i','y','pr','e','h','N','caput'})    
    
%% Ramey adj. series
data = [real_private_cons_22(1:end);real_percapita_inv_22(1:end);real_percapita_gdp_22(1:end);...
         productivity_1(1:end);employment_rate_22(1:end);log(weekly_hours(1:end-4));hours_percapita_22(1:end);caput(1:end-4)];


else
    
   
%% Benchmark

data = [real_private_cons(1:end);real_percapita_inv(1:end);real_percapita_gdp(1:end);...
    productivity_0(1:end);employment_rate(1:end);log(weekly_hours(1:end-4));hours_percapita_NBS(1:end);caput(1:end-4)];



end

time = 1948:0.25:2007.75; %% (counting the missing observation)

  