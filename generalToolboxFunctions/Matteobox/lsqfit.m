function [fitq,fitp,exitflag,output] = lsqfit(modelname,data,minpars,inipars,maxpars,options,varargin)
% LSQFIT least squares fitting of a model (using 'lsqcurvefit')
% 
% [fitq,fitp,exitflag,output] = lsqfit(modelname,data,minpars,inipars,maxpars,options,varargin)
%
% minpars and maxpars are lower and upper boundaries in the fit
% inipars are starting points in the fit
% options are [MaxFunEvals/npars MaxIter]
% varargin are inputs to the model (after the vector of parameters)
%
% Outputs are
% - fitq: the percentage of variance explained
% - fitp: the optimal parameters
% - exitflag and output: information about the fit from lsqcurvefit
% 
% see also FITIT
%
% 2003-10 Valerio Mante made it

% The options for the fit
if isempty(options)
   % [MaxFunEvals/nvariables MaxIter]
   options = [600 2000];
end

% Find the fixed parameters
npars = length(minpars);
fixpars = zeros(2,npars);
% The parameters that are fixed
fixpars(1,:) = (inipars == maxpars);
fixpars(2,:) = inipars;

% The parameters that vary
imod = find(fixpars(1,:) == 0);

% Options of lsqcurvefit
MaxFunEvals = options(1)*length(imod);
MaxIter = options(2);
lsqoptions = optimset('display','iter','MaxIter',MaxIter,'MaxFunEvals',MaxFunEvals);

% The string that evaluated the fit
[modp,resnorm,residual,exitflag,output] = ...
   lsqcurvefit(@runmodel,inipars(imod),modelname,data,minpars(imod),maxpars(imod),lsqoptions,fixpars,varargin{:});

% The optimal parameters
fitp = fixpars(2,:);
fitp(imod) = modp;

% The model response with the optimal parameters
rfit = eval([modelname '(fitp,varargin{:})']);

% The percentage of variance explained
fitq = 100*(1 - sum((data(:) - rfit(:)).^2)/sum((data(:) - mean(data(:))).^2));

