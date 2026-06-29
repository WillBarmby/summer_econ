

%%% COMPUTES STATISTICS FROM FORECAST ERRORS

clear all;clc

%% 1. Upload actual data and forecasts


 %%  Real GDP. 
 
 %%Here we have different data vintages. We follow SPF and
 %% consider five vintages:
 %% - first available
 %% - second available
 %% - fifth available
 %% - ninth available
 %% - final release
 
  
    %% Forecasts (1-4Qs ahead)
   
        RGDP_forecast_mat = xlsread('RealGDP_forecast','GDP SPF','G4:J165');
   
        
    %% NOTE: the data ranges from 1968Q4 to 2009Q1
   
 
 
   %% First vintage available
   
     load real_gdp_growth_v1
 
     %% NOTE: the series ranges from 1947Q1-2009Q1
 
   %% Forecast errors 1Q ahead
   
   RealGDP_fe_v1_1Q = real_time_gdp_growth_v1(87+1:end)-RGDP_forecast_mat(1:end-1,1);
   
   
   
   %% Autocorrelation in forecast errors
   
   
      %% 1Q ahead   
      disp('Autocorrelation in forecast errors: 1st vintage')
      RealGdp_v1_auto_fe_1Q = corr(RealGDP_fe_v1_1Q(2:end),RealGDP_fe_v1_1Q(1:end-1))
   
   
   %% Second vintage available
   
     load real_gdp_growth_v2
     
   
    %% Forecast errors 1Q ahead
   
    
    
   RealGDP_fe_v2_1Q = real_time_gdp_growth_v2(87+1:end)-RGDP_forecast_mat(1:end-1,1);
   
   
   
   
   
     %% Autocorrelation in forecast errors
   
     
      
      %% 1Q ahead   
    disp('Autocorrelation in forecast errors: 2nd vintage')  
     
   RealGdp_v2_auto_fe_1Q = corr(RealGDP_fe_v2_1Q(2:end),RealGDP_fe_v2_1Q(1:end-1))
   
   
 
   %% Fifth vintage available
   
     load real_gdp_growth_v5
     
   
   %% Forecast errors 1Q ahead
   
   RealGDP_fe_v5_1Q = real_time_gdp_growth_v5(87+1:end)-RGDP_forecast_mat(1:end-1,1);
   
   
   
   %% Autocorrelation in forecast errors
   
      
      %% 1Q ahead   
      disp('Autocorrelation in forecast errors: 5th vintage')
      RealGdp_v5_auto_fe_1Q = corr(RealGDP_fe_v5_1Q(2:end),RealGDP_fe_v5_1Q(1:end-1))
 
   
   
   %% Ninth vintage available
   
     load real_gdp_growth_v9  %% This contains also the last vintage
      
   
   
   %% Forecast errors 1Q ahead
   
   RealGDP_fe_v9_1Q = real_time_gdp_growth_v9(87+1:end)-RGDP_forecast_mat(1:end-1,1);
   
 
   %% Autocorrelation in forecast errors
   
   
      
      %% 1Q ahead
         disp('Autocorrelation in forecast errors: 9th vintage')
      RealGdp_v9_auto_fe_1Q = corr(RealGDP_fe_v9_1Q(2:end),RealGDP_fe_v9_1Q(1:end-1))
 
   
   
   
   
   %% Forecast errors 1Q ahead
   
   RealGDP_fe_vL_1Q = final_vintage_growth_gdp(87+1:end)-RGDP_forecast_mat(1:end-1,1);
   
   
   %% Autocorrelation in forecast errors
   
   
      %% 1Q ahead
      disp('Autocorrelation in forecast errors: Last vintage')
   RealGdp_vL_auto_fe_1Q = corr(RealGDP_fe_vL_1Q(2:end),RealGDP_fe_vL_1Q(1:end-1))
   
   
