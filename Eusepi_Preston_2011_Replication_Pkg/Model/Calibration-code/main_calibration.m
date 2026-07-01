

%%%% MAIN FILE CALIBRATION




clear all
%clc

pkg_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(pkg_dir, 'Common'), '-end');



global  epsZ




%% [1] GENERATES SHOCKS

%% NOTE: make sure the number of shocks is consistent with the model

 epsZ = randn(1,50200); 

 save shocks_mat epsZ

 %load shocks_mat

 
%% [2] Minimzation 
 
 


 opt0 = [0.0632];

 
 %% correcting gradient
 
 
 size_vector = [1e-2];
 
 
 GMat = diag(size_vector);
 
 
[fh,opt_x,gh,H,itct,fcount,retcodeh] = csminwel('Obj_fun_Sept_2009',opt0,GMat,[],1e-7,10000)

%Obj = Obj_fun_Sept_2009(opt0)
