function [ err, pars ] = fit_hyper_ratio(cs,resps,nn,R0)
%  [ err, pars ] = fit_hyper_ratio(cs,resps,nn,R0)
% FIT_HYPER_RATIO fits hyper_ratio to the data
%
% 	[ err, pars ] = fit_hyper_ratio(cs,resps)
% 	[ err, pars ] = fit_hyper_ratio(cs,resps,nn) uses nn starting points (Default:3)
% 	[ err, pars ] = fit_hyper_ratio(cs,resps,nn,R0) imposes an R0
%
%  hyper_ratio pars are [ Rmax, sigma, n, R0 ]
%
% 1998 Matteo Carandini
% 2002 MC
%
% part of the Matteobox toolbox
%
% see also: hyper_ratio

if nargin < 3
   nn = 3;
end

if nargin == 4
   fixR0 = 1;
else
   fixR0 = 0;
end

cs = cs(:);
resps = resps(:);

if any(~isfinite(cs)) | any(~isfinite(resps))
   error('yoooooooo');
end

if size(cs)~=size(resps)
   error('yo');
end

% -------------- initial values

if ~fixR0
   if any(cs==0)
      R0 = mean(resps(cs==0));
   else 
      R0 = 0;
   end
end

Rmax = max(resps);
n = 2.5;
sigma = mean(cs);

% -------------- do the fit

if fixR0
   [ err pars ] = fitit('hyper_ratio',resps,...
      [ 0 eps 0 R0 ], [ Rmax, sigma, n, R0 ], [ 2*Rmax max(cs)*1.5 5 R0 ], [0 1e-4 1e-4 nn], cs );
else
   [ err pars ] = fitit('hyper_ratio',resps,...
      [ 0 eps 0 0 ], [ Rmax, sigma, n, R0 ], [ 2*Rmax max(cs)*0.5 5 Rmax ], [0 1e-4 1e-4 nn], cs );
end


