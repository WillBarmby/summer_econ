
%% THIS FUNCTION COMPUTES THE ALM OF A MODEL DEFINED BY:
%% matrices A, B
%% PLM OMEGA_0, OMEGA_c
%% k_y (finite) number of forecast ahead
%% disc: vector of discount rates (to be used in the infinite horizon
%% forecasts

%% The first three matrices describe the ALM, the last two can be used in
%% the Estab function to compute Estability of the REE

 function [T_0 T_L T_s T_c T_Ls] = ALM_fun(A,C,invA0,OMEGA_0,OMEGA_c,k_y,disc)

  %% First verify that marix dimensions match 
 
 if size(A{1},1) ~= size(OMEGA_0,1)
     
     disp('model not correctly specified')
     return
     
 end
 
 if size(A{1},1) ~= size(OMEGA_c,1)
     
     disp('model not correctly specified')
     return
     
 end
 
 
 %% Define parameters
 
 n_var = size(A{1},1);
 
 j_y = length(disc);
 
 
 
 %% Infinite horizon expectations
 
 invOM = inv(eye(n_var)-OMEGA_c);
 
 for cnt = 1:j_y
     
     F0{cnt} = invOM*(eye(n_var)*(1-disc(cnt))^(-1)-OMEGA_c*inv(eye(n_var)-disc(cnt)*OMEGA_c))*OMEGA_0;
     
     F1{cnt} = OMEGA_c*inv(eye(n_var)-disc(cnt)*OMEGA_c);
 
 end
 
 %disp('forecast has been created')
 
 
%% ALM


T_0 = invA0*A{1}+invA0*A{2}*OMEGA_0;

T_c = zeros(n_var,n_var);


for ctn = 1:k_y
   
    
T_0 = T_0+invA0*A{2+ctn}*invOM*(eye(n_var)-OMEGA_c^(ctn))*OMEGA_0;


T_c = T_c+invA0*A{2+ctn}*OMEGA_c^(ctn);

 end

for ctn = 1:j_y
    
    T_0 = T_0+invA0*A{2+k_y+ctn}*F0{ctn};
    
    T_c = T_c+invA0*A{2+k_y+ctn}*F1{ctn};
end

T_Ls = invA0*A{2}*OMEGA_c+invA0*A{2+k_y+j_y+1};

%clear A invA0 F0 F1 

%disp('calculating last inverse')

T_inv = inv(eye(n_var,n_var)-T_c);

%disp('done calculating last inverse')

T_0 = T_inv*T_0;

%disp('done calculating constant')
T_L = T_inv*T_Ls;

%disp('done calculating coefficients')

T_s = T_inv*C;

%disp('ALM created')
    