function [fitr,fitp,exitflag,output] = fminfit(modelname,minpars,inipars,maxpars,options,varargin)
% fminfit minimize the distance between model and data using fmincon
% 
% [fitr,fitp,exitflag,output] = fminfit(modelname,minpars,inipars,maxpars,options,varargin)
%
% minpars and maxpars are lower and upper boundaries in the fit
% inipars are starting points in the fit
% options are [MaxFunEvals/npars MaxIter]
% varargin are inputs to the model
%
% Outputs are
% - fitr: the model response at the minimum
% - fitp: the optimal parameters
% - exitflag and output: information about the fit from fmincon
%
% 2003-10-13 VM made it
%
% [fitr,fitp,exitflag,output] = fminfit(modelname,minpars,inipars,maxpars,options,varargin)


% The options for the fit
if isempty(options)
   % [MaxFunEvals/nvariables MaxIter]
   options = [400 2000];
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
lsqoptions = optimset('largescale','off','display','iter','MaxIter',MaxIter,'MaxFunEvals',MaxFunEvals);

% Minimize
[modp,resnorm,residual,exitflag,output] = ...
   fmincon(@runmodel,inipars(imod),[],[],[],[],minpars(imod),maxpars(imod),[],lsqoptions,modelname,fixpars,varargin{:});

% The optimal parameters
fitp = fixpars(2,:);
fitp(imod) = modp;

% Model response
fitr = eval([modelname '(fitp,varargin{:})']);


