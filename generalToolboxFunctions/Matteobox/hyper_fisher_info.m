function fi = hyper_fisher_info(pars,cs)
% computes the square of the hyperbolic ratio slope divided by the response
%
% Note that pars now needs an R0 term if you plan to get sensible results 
% The hyperbolic ratio is computed as 
%	f = hyper_ratio([ Rmax, sigma, n, R0 ],cs)
%	gives f = Rmax* cs.^n./(sigma^n+cs.^n) + R0
%	
% 1995-1998 Matteo Carandini
% 1999 Matteo Carandini, check for zero denominators
% part of the Matteobox toolbox
% 2009 ARW

if length(pars(:))~=4
   error('You need to specify 4 parameters');
end

Rmax 	= pars(1);
sigma = pars(2);
n 		= pars(3);
R0 	= pars(4); 

fi=((hyper_ratio_slope(pars,cs)).^2)./(hyper_ratio(pars,cs));
