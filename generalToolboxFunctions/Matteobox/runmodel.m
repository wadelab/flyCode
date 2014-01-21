function rr = runmodel(modpars,modelname,fixpars,varargin)
% runmodel implement a model such that it can be fitted with lsqcurvefit
%
% Works for model of the form:
%  modelname(pars,varargin)
%
% Inputs are:
% modpars: the subset of parameters that vary in the fit
% modelname: the model to fit
% fixpars: which parameters are fixed and value do they have
% varargin: the inputs to the model
%
% 09-09-2003 VM made it
%
% rr = runmodel(modpars,modelname,fixpars,varargin)

% The number of parameters
npars = size(fixpars,2);

% Get the parameters
if ~isempty(fixpars)
   pars = zeros(1,npars);
   ifix = find(fixpars(1,:) == 1);
   imod = setdiff(1:npars,ifix);
   pars(imod) = modpars;
   pars(ifix) = fixpars(2,ifix);
else
   pars = modpars;
end

% Evaluate the model with these parameters
rr = eval([modelname '(pars,varargin{:})']);

return



% Code to test the function

pars = [0.005 2 0.010 0 2 2 0.5 1 ];

fixpars(1,:) = [0 0 1 0 1 0 1 0];
fixpars(2,:) = pars;

ifix = find(fixpars(1,:) == 1);
imod = setdiff(1:length(fixpars),ifix);
modpars = pars(imod);

dt = 0.001;
mtir.tt = 0:dt:0.500;

rlsq = runmodel(modpars,'dogammas02',fixpars,mtir,0);
rr = dogammas02(pars,mtir,0);

figure; plot(rlsq,rr);
