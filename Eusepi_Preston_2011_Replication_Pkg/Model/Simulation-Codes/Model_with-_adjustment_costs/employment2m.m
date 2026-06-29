
clear
%% ANOTHER FILE ANALYZING EMPLOYMENT

weekly_hours = xlsread('employment2', 'Sheet1', 'B5:B248');
weekly_hours = weekly_hours';

employment = xlsread('employment2', 'Sheet1', 'c5:c248');
employment = employment';

total_hours = xlsread('employment2', 'Sheet1', 'D5:D248');
total_hours = total_hours';

y_obsl = [log(weekly_hours);log(employment);log(total_hours)];

hp_data_sample = y_obsl';

 
 [y_sample_trend,desvabs] = hpfilter(hp_data_sample,1600);
 

 
  data_sampled = hp_data_sample'-y_sample_trend';
     
    
    std_data_full = std(data_sampled,0,2);

    variance = var(data_sampled,0,2);