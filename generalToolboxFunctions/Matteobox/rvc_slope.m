function rr = rvc(pars,cc,maxc) 
% RVC aggregate contrast response function R = k c^(m+n)/[sigma^m + c^m]
%
% rr  = rvc([ k, m, n, sigma ],cc)
% where cc is a vector of contrasts, is the function
% R(c) = k c^(m+n)/ [sigma^m + c^m]
%
% rr  = rvc([ k, m, n, sigma, a ],cc) 
% where cc is a vector of contrasts, is the function
% R(c) = k c^(m+n)/ [sigma^m + c^m] + a c
%
% ct = rvc(pars,cps,maxc) lets you pick if contrasts are bet 0 and 1 (maxc = 1)
% or bet 0 and 100 (maxc = 100, default)
%
% 2000-01 Matteo Carandini
% part of the Matteobox toolbox

if nargin<3
   maxc = 100;
end

k 		= pars(1);
m 		= pars(2);
n 		= pars(3);
sigma	= pars(4);

if length(pars) < 5
   a = 0;
else
   a = pars(5);
end

cc = cc/maxc;
sigma = sigma/maxc;

rr = k * cc.^(m+n) ./ (sigma^m + cc.^m) + a*cc;

