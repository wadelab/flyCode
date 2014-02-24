function cts = tvc(pars,cps,maxc,logflag) 
% TVC threshold vs contrast function
%
% cts = tvc(pars,cps)
% where cps is a vector of pedestal contrasts, is the threshold expected from the contrast
% response function rvc(pars,cps). 
%
% The threshold is computed numerically, not simply taking the inverse of the derivative.
%
% cts = tvc(pars,cps,maxc) lets you pick if contrasts are bet 0 and 1 (maxc = 1)
% or bet 0 and 100 (maxc = 100, default)
%
% cts = tvc(pars,cps,maxc,'log') takes the log of cts. This is useful for fitting data in log space.
% 
% EXAMPLE:
% cps = logspace(-4,0);
% pars = [20 2 0.2 0.25 1];
% cts = tvc(pars,cps,1);
% loglog(cps,cts);
%
% 2000-01 Matteo Carandini
% part of the Matteobox toolbox

if nargin<4
   logflag = 'linear';
end

if nargin<3
   maxc = 100;
end

ccc = maxc*logspace(-4,0,10000);

rrr = rvc(pars, ccc, maxc);

ncps = length(cps);

cts = zeros(1,ncps);
for ic = 1:ncps
   cp = cps(ic);
   icp = find( abs(cp-ccc)==min(abs(cp-ccc)) );
   r2 = rrr(icp)+1;
   if all(rrr<r2)
      ct = maxc; % used to be inf, which is more appropriate but problematic when fitting
   else
      ict = find( abs(rrr-r2)==min(abs(rrr-r2)) );
      ct = ccc(ict)-cp;
   end
   cts(ic) = ct;
end

if strcmp(logflag,'log')
   cts = log10(cts);
end


