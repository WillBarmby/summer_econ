 function ini_VCV = VCV_Model(T_L_RE,T_s_RE,var_model)



%% Compute the second moments

%% Solves Riccati equation...
 
maxit = 10000000;
 
 tol = 1e-10;
       
             
    d = T_s_RE*var_model*T_s_RE';
 
%  [v,info] = doublej(g,d,h,tol,maxit)  uses a doubling algorithm
%   to solve the  Sylvester equation
%         v  = d + g v h

 [v,info] = doublej(T_L_RE,d,T_L_RE',tol,maxit);

 
%% Select second moments of the variables r and b + the constant 

ini_VCV = v;


