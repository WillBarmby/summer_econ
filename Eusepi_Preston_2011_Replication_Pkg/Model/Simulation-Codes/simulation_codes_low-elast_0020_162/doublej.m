function [v,info] = doublej(g,d,h,tol,maxit)
% NOTE
% DOUBLEJ  Solves a Sylvester equation using doubling
% USED TO BE DOUBLES IN EVANANDERSON MALTLAB
% written by E.W. Anderson (1994) - Modified (1998)
% Modified by O. Mikhail
%  [v,info] = doublej(g,d,h,tol,maxit)  uses a doubling algorithm
%   to solve the  Sylvester equation
%         v  = d + g v h
%  for v.  Currently, the output variable info is not set. 
%   Iteration is stopped at iteration n when either n=maxit or when
%          norm{v(n) - v(n-1)}  <=  tol* norm{v(n)}
%   where v(n) is the  approximation for v computed in the
%   nth iteration and norm is the matrix one norm. 
v = d;
for i =1:maxit,
   vadd = g*v*h;
   v = v+vadd;
   if norm (vadd,1) <= (tol*norm(v,1)),
      break;
   end  
   g = g*g;
   h = h*h; 
end 
info=0;

