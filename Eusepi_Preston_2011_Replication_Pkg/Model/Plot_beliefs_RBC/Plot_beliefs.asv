


%%% THIS FILE PLOTS THE DISTRIBUTION OF AGENTS' ESTIMATES

clear all;clc

load beliefs_mat_RBC_feedback
  COEFF_STORE2_feedback1 = COEFF_STORE;
 
 clear COEFF_STORE2
 
 load beliefs_mat_RBC_no_feedback

 COEFF_STORE2_no_feedback1 = COEFF_STORE;
 
 
COEFF_STORE2_feedback{1} = COEFF_STORE2_feedback1{1}(:,1:end-2);
COEFF_STORE2_feedback{2} = COEFF_STORE2_feedback1{2}(:,1:end-2);
COEFF_STORE2_feedback{3} = COEFF_STORE2_feedback1{7}(:,1:end-2);

COEFF_STORE2_no_feedback{1} = COEFF_STORE2_no_feedback1{1}(:,1:end-2);
COEFF_STORE2_no_feedback{2} = COEFF_STORE2_no_feedback1{2}(:,1:end-2);
COEFF_STORE2_no_feedback{3} = COEFF_STORE2_no_feedback1{7}(:,1:end-2);


%% Generates beliefs distribution

n_eq = 3; %% number of equations the agents estimate

n_x = 1; %% number of regressor (excl. constant)

n_c = 1; %% intercept

[f_vec,x_vec,f_n_vec,mu_vec,sigma_vec] = distr_fun(n_eq,n_x,n_c,1,COEFF_STORE2_feedback);

[f_vec1,x_vec1,f_n_vec1,mu_vec1,sigma_vec1] = distr_fun(n_eq,n_x,n_c,1,COEFF_STORE2_no_feedback);


%% we can adjust for the "bias" in agents' estimates which is induced by the feed-back

for j1 = 1:n_eq
    
x_vec{j1}(2,:)=x_vec{j1}(n_c+1,:)+mu_vec1{j1}(n_c+1)-mu_vec{j1}(n_c+1);

end



%% Plot figures

%load OMEGA_mat

% for j1 =1:n_eq
%     
% Regressors_RE{j1} = [0;OMEGA_c(j1,3)];
% 
% end
 figure 
for j1 = 1:n_eq
    
   
    
    for j2 = 1:n_x+n_c
     
        if j1 == 1
        j2b = j2;
        
        end
        
        if j1 == 2
        j2b = j2+2;
        
        end
        
        if j1 == 3
        j2b = j2+4;
        
        end
     subplot(3,2,j2b)
     
%      plot(x_vec{j1}(j2,1:end),f_vec{j1}(j2,1:end),...
%          x_vec{j1}(j2,1:end),f_n_vec{j1}(j2,1:end),...
%        ones(1,length(f_vec{j1}(j2,1:end)))*Regressors_RE{j1}(j2),f_vec{j1}(j2,1:end));
%     
     plot(x_vec{j1}(j2,1:end),f_vec{j1}(j2,1:end),...
         x_vec1{j1}(j2,1:end),f_vec1{j1}(j2,1:end));
    

    end
    
end

save beliefs_mat_RBC_feedback COEFF_STORE2
 