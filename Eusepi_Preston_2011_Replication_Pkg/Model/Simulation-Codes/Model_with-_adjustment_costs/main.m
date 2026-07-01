
%%%

clear all;clc

pkg_dir = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(pkg_dir, 'Common'), '-end');

for jj = 1:5000
    
    jj
    
    f=1;
    
    [Model_moments_std,Model_moments_auto,FErk_corr] =  BC_statistics_adj_cost_model(f);
    
    
    Model_moments_std_mat(:,jj) = Model_moments_std;
    
    Model_moments_auto_mat(:,jj) = Model_moments_auto;
    
    Model_FErk_corr_mat(jj) = FErk_corr;
    
end


 mean(Model_moments_std_mat')'
 
 mean(Model_moments_auto_mat')'
 
 mean(Model_FErk_corr_mat)
 
 std(Model_FErk_corr_mat)
