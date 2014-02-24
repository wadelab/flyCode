function f = hyper_ratio_tuned(pars,cs)
% HYPER_RATIO  hyperbolic ratio function, eg to fit contrast responses
%
%	f = hyper_ratio([ Rmax, sigma, n, R0 ],cs)
%	gives f = Rmax* cs.^n./(sigma^n+cs.^n) + R0
%	cs is a column vector of contrasts. If cs has 2 columns, the first is
%	the effective contrast of the stimulus and the second is the effective
%	contrast of the normalization pool.
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

switch size(cs,2)
    case 1
        numerator = (Rmax*csn(:));
        denominator = (sigma^n+csn(:));
    case 2
      numerator = (Rmax*csn(:,1));
        denominator = (sigma^n+csn(:,2));
    otherwise
            error('Contrast must be a nx1 or nx2 array');
end

if denominator>0
   f = numerator./denominator + R0;
else
   f = Inf*ones(size(cs));
   error ('Dividing by a zero normalization pool');
   
end

