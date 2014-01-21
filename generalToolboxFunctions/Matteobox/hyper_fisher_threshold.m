function thresh = hyper_fisher_threshold(pars,cs)
% computes a visual threshold based on the inverse root of the fisher
% information
%
% Note that pars now needs an R0 term if you plan to get sensible results 
% The hyperbolic ratio is computed as 
%	f = hyper_ratio([ Rmax, sigma, n, R0 ],cs)
%	gives f = Rmax* cs.^n./(sigma^n+cs.^n) + R0
%	pars should have two additional entries: Pars(6) is the Poisson
%	exponent of the noise distribution (defaults to 1) and pars (5) is a
%	baseline noise entry (also defaults to 1).
% 1995-1998 Matteo Carandini
% 1999 Matteo Carandini, check for zero denominators
% part of the Matteobox toolbox
% 2009 ARW

if length(pars(:))<4
   error('You need to specify at least 4 parameters');
end

Rmax 	= pars(1);
sigma = pars(2);
n 		= pars(3);
R0 	= pars(4); 
noiseBase=0.01;
poissonExp=1;
if (length(pars(:))>4)
    noiseBase=pars(5);
    
end
if (length(pars(:))>5)
    poissonExp=pars(6);
end

%thresh=(((hyper_ratio(pars(1:4),cs))))./((hyper_ratio_slope(pars(1:4),cs))+noiseBase);


thresh=1./((hyper_ratio_slope(pars(1:4),cs)))+noiseBase;
