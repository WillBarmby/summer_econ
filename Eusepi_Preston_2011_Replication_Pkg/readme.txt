

%% This is a decription of the replication files for the paper:"Expectations, Learning and Business Cycle Fluctuations" by Stefano Eusepi and Bruce Preston





%% We have organized the files in different forlders, corresponding to the different results in the paper
 

%% The folders are:

1. Data: 

1.1. Expectations_data. Contains the dataset used for Expectatrions. 
	(a) The file "Survey_forecast_Errors_.xls" contains the data fron SPF and 		     the statistics reported in Table 1.
        (b) The Matlab file "GDP_forecast_statistics_Oct_2009" computes the frist 	            order autocorrelation fro GDP forecast errors of SPF forecasts for 	               different vintages described in Table 1. The folder also includes 	               files with the data sources.
1.2  Macrodata. The matlab file "data_statistics.m" produces the statistics in             Table 2 (business cycle statistics -- Data column)



2. Model. 


2.1    Calibration code: computes the calibrated standard deviation of the               technology shock in the simple RBC model (REE and learning) and in the        model with  nonseparable preferences, capacity utilization and        externalities.  


2.2    Simulation code: Contains folders corresponding to the results reported in         Tables 2-3-4-5. Each code produces the business cycle statistics for the        model. In particular, the file "main_stats" produces the variables:
   
       mean_L, std_L, mean_G, std_G, mean_autog, std_autog (compute business cycle        statistcs for the simulated data, HP filterd and in growth rates)

       mean_arki std_arki, mean_awi std_awi, i=1,2,3,4, (compute the statistics        for  simulated forecast errors)

  
  
      Shared Matlab functions used by multiple folders are stored in the
      package-level folder "Common". The common simulation driver
      "main_stats.m" is stored in "Model/Simulation-Codes"; run it while the
      current Matlab folder is the target simulation folder. Scenario folders
      that require a different driver still keep their local "main_stats.m".
      The Euler-specific shared model simulation file is stored in
      "Model/Simulation-Codes/Euler_common".

2.2.1 For Table 1-2, The folders are:

      simulation_codes_gamma_0020_162
      simulation_codes_gamma_0020_110
     

      simulation_codes_gamma_0000_162
      simulation_codes_gamma_0000_110



2.2.2 For Table 3

      simulation_nonseps_codes_gamma_0010_162
      simulation_nonseps_codes_gamma_0000_162

2.2.3 For Table 4

      simulation_codes_gamma_0013_162
      simulation_codes_gamma_0015_162
      simulation_codes_gamma_0017_162
      simulation_codes_gamma_0020_162
      simulation_codes_gamma_0025_162
      simulation_codes_gamma_0027_162
      simulation_codes_gamma_003_162

2.2.4 For Table 5

   (a)  simulation_codes_low elast_0020_162
        simulation_codes_low_elast_0000_162

        simulation_codes_Euler_162
        simulation_codes_Euler_sg_162
  
   (b)  The code to simulate the model with adjustment costs is different. The             folder is: Model_with_adjustment_costs. The main file is "main.m" 


2.3. For Impulse responses, the folder: Plot_imp_resp_Bench, plots the impulse          responses in Figures 1-3. The folder: Impulse responses, generates the           impulse response in the model. The main file is "Main_imp_resp_Sept_2009".  


2.4. The folder: Plot_belief_RBC plots the beliefs distributions in Figure 4. The       main file is "Plot_beliefs.m". The belies are generated using the simulation      codes in 3. (set option: "store = 1" in the file "Model_Simul_Oct_2009.m".




    
   
