function yy = expfunc(pars,tt)
% EXPFUNC exponential decay function
%
%	yy = expfunc([y0,dy,tau],tt) gives yy = (y0+dy)- dy* exp(-tt/tau);
%
% 1996 Matteo Carandini
% part of the Matteobox toolbox

y0  = pars(1);
dy  = pars(2);
tau = pars(3);
yy = (y0+dy)- dy* exp(-tt/tau);
