function f = hyper_ratio(pars,cs)
% function f = hyper_ratio(pars,cs)
% HYPER_RATIO  hyperbolic ratio function, eg to fit contrast responses
%
%	f = hyper_ratio([ Rmax, sigma, n, R0 ],cs)
%	gives f = Rmax* cs.^n./(sigma^n+cs.^n) + R0
%	
% 1995-1998 Matteo Carandini
% 1999 Matteo Carandini, check for zero denominators
% part of the Matteobox toolbox
pars=pars(:);

if length(pars(:))~=4
   error('You need to specify 4 parameters');
end

Rmax 	= pars(1);
sigma = pars(2);
n 		= pars(3);
R0 	= pars(4); 

csn = cs.^n;
denominator = (sigma^n+csn);

if denominator>0
   f = Rmax* csn./denominator + R0;
else
   f = Inf*ones(size(cs));
   error
   
end

