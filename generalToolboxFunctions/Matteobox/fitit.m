function [dist,f] = fitit( model,data,parmins,initpars,parmaxs,options,P1,P2,P3,P4,P5,P6,P7,P8,P9,P10,P11,P12)
% FITIT least squares fitting of a model (based on 'fmins')
%
% 	[DIST,P]=fitit('MODEL',Y,PMIN,P0,PMAX,OPTIONS,X) 
%	searches for the parameters P that minimize the square cartesian 
%	distance between MODEL(P,X) and the data Y. 
%	DIST is the minimum square cartesian distance obtained. 
%
%	PMIN and PMAX are the boundaries in which the search is made.
%	P0 is the initial point for the first iteration of the algorithm.
%	If P0 is [] the search starts halfway between PMIN and PMAX.
%
% 	[DIST,P]=fitit('MODEL',Y,PMIN,P0,PMAX,OPTIONS,X,P1,P2,..) 
%	lets you specify additional parameters that may be needed by your MODEL.
%	They will be used as in MODEL(P,X,P1,P2,...).
%
% 	[DIST,P]=fitit('MODEL',Y,PMIN,P0,PMAX,OPTIONS,X,P1,P2,..,WEIGHTS) 
%	lets you specify WEIGHTS. WEIGHTS it must have same dimension as X and Y.
%	it is considered a set of weights ONLY if OPTIONS(6) is 1, 
%	otherwise it is considered a parameter of the model. 
%	NOTE that distances are scaled by weights BEFORE squaring.
%
%	The output of the model can be COMPLEX, but the parameters have to be REAL 
%
%	OPTIONS(1)-Display parameter (Default:1). 0 = nothing, 1 = something, 2 = a lot
%	OPTIONS(2)-Termination tolerance for X.(Default: 1e-4).
%	OPTIONS(3)-Termination tolerance on cartesian distance.(Default: 1e-4).
%	OPTIONS(4)-Number of random starting points (Default:50).
%	OPTIONS(5)-Max number of iterations per parameter (Default:10000).
%	OPTIONS(6)-set to 1 if last of the Ps is a set of weights (Default:0).
%
%	This function is part of matteobox, and is 
%	adapted from Matlab's "fmins". (Matteo Carandini 1994-95-97-00)
%  
% see also LSQFIT (which is faster but might not have all the functionality)
%
% %%%%%%%%%%%%%%%%%%  EXAMPLE OF USE %%%%%%%%%%%%%%%%%%%%%%5
%
%  addpath('c:/users/Matteo/matlab/toolbox5/matteobox');
%  
%  xx = 0:100;
%  
%  yyfake = gaussian([30 40 5 10],xx)+rand(size(xx));
%  
%  plot(xx,yyfake,'o');
%  
%  [dist,fitpars]=fitit('gaussian',yyfake,...
%     [0 0 0 0], [], [100 50 50 30],...
%     [],xx);
%  
%  plot(xx,gaussian(fitpars,xx),'-', xx, yyfake, 'o');
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 1995-2000 Matteo Carandini
% part of the Matteobox toolbox

% change log
% 5/28/2005 vb bestparams now initialized to params before iter

if nargin<5, error('Must specify at least MODEL, DATA, XMINS, X0, XMAXS'); end

if size(parmins)~=size(parmaxs), error('XMINS and XMAXS must have same size'); end

if any(parmaxs<parmins)
	error('The upper limits must be higher than the lower limits');
end

mask = (parmins == parmaxs);

if length(initpars) == 0
	initpars = (parmins+parmaxs)/2; 
elseif any(initpars<parmins|initpars>parmaxs)
	disp('WARNING: The starting point X0 is out of bounds.');
	disp(' Starting at arbitrary X0.'); 
	initpars = (parmins+parmaxs)/2; 
end

initpars(mask) = parmins(mask);      % just to make sure it is within bounds.
params = initpars;

if nargin<6, options = []; end
defaults = [ 1 1e-4 1e-4 5 10000 0 ];
options = [ options defaults(length(options)+1:6) ];

prnt = options(1);
tol  = options(2);
tol2 = options(3);
niter= options(4); 
maxiter = options(5);
weighted= options(6);

if weighted & nargin<=6, 
   error('you said you want to use weights but you did not specify them!'); 
end

if weighted, 
	weights = eval(['P' int2str(nargin-6)]); 
else 
	weights = ones(size(data)); 
end

if any(isinf(weights)|isnan(weights))
	error('Gotta have finite weights');
end

if all(weights==0)
	weights = ones(size(data)); 
end
	
if size(weights)~=size(data), 
   error('Weights and data have different dimensions'); 
end

if any(model<48), error('Something wrong with the MODEL name'); end
modelstr = [ model '(params'];
for ii=1:nargin-6-weighted, modelstr = [modelstr,',P',int2str(ii)]; end
modelstr = [modelstr, ')'];

if size(data) ~= size(eval(modelstr))
	error('MODEL should return data of same dimension as DATA');
end

evalstr = ['sum(sum( (abs(data-' modelstr ').*weights).^2 ))'];
if isnan(evalstr)
	error('Fitit cannot deal with NaNs');
end

n = prod(size(find(~mask)));
options(5) = options(5)*n;

%--------------------- HERE IS A WRAPPER that considers random starting points;

bestf = eval(evalstr); 	% it should be easy to do better than that...

if prnt
	disp(['Distance is ' num2str(bestf,4) ' with parameters ' mat2str(params,2)]);
end

bestparams = params; % 5/28/05 vb

for iter = 1:niter+1
  %  fprintf('.');
    
if iter>2, params = parmins + rand(size(parmins)).*(parmaxs-parmins); end 
% this ensures that the alg runs twice on the first set of pars

%------------------------- FIRST PART OF WRAPPER ENDS HERE 

x = params(~mask); 		

% Set up a simplex near the initial guess.
xin = x(:); % Force xin to be a column vector
v = xin;    % Place input guess in the simplex! (credit L.Pfeffer at Stanford)
x(:) = v; params(~mask) = x;  
if all(params>=parmins&params<=parmaxs), fv = eval(evalstr); else, fv = Inf; end

% Following improvement suggested by L.Pfeffer at Stanford
usual_delta = 0.05;             % 5 percent deltas for non-zero terms
zero_term_delta = 0.00025;      % Even smaller delta for zero elements of x
for j = 1:n
   y = xin;
   if y(j) ~= 0
      y(j) = (1 + usual_delta)*y(j);
   else
      y(j) = zero_term_delta;
   end
   v = [v y];
   x(:) = y; params(~mask) = x; f = eval(evalstr);
   if all(params>=parmins&params<=parmaxs), f = eval(evalstr); else, f = Inf; end
   fv = [fv  f];
end
[fv,j] = sort(fv);
v = v(:,j);


cnt = n+1;
if prnt==2
   clc
   format compact
   format short e
   home
   cnt
   disp('initial ')
   disp(' ')
   v
   f
end

alpha = 1;  beta = 1/2;  gamma = 2;
[n,np1] = size(v);
onesn = ones(1,n); 
ot = 2:n+1;
on = 1:n;

% Iterate until the diameter of the simplex is less than tol.
while cnt < options(5)
    if max(max(abs(v(:,ot)-v(:,onesn)))) <= tol & ...
           max(abs(fv(1)-fv(ot))) <= tol2
        break
    end

    % One step of the Nelder-Mead simplex algorithm

    vbar = (sum(v(:,on)')/n)';
    vr = (1 + alpha)*vbar - alpha*v(:,n+1);
    x(:) = vr;
    params(~mask) = x;  
    if all(params>=parmins&params<=parmaxs), fr = eval(evalstr); else, fr = Inf; end
    cnt = cnt + 1; 
    vk = vr;  fk = fr; how = 'reflect ';
    if fr < fv(n)
        if fr < fv(1)
            ve = gamma*vr + (1-gamma)*vbar;
            x(:) = ve;
            params(~mask) = x; 
            if all(params>=parmins&params<=parmaxs), fe = eval(evalstr); else, fe = Inf; end
	    cnt = cnt + 1;
            if fe < fv(1)
                vk = ve; fk = fe;
                how = 'expand  ';
            end
        end
    else
        vt = v(:,n+1); ft = fv(n+1);
        if fr < ft
            vt = vr; ft = fr;
        end
        vc = beta*vt + (1-beta)*vbar;
        x(:) = vc;
        params(~mask) = x;  
        if all(params>=parmins&params<=parmaxs), fc = eval(evalstr); else, fc = Inf; end
        cnt = cnt + 1;
        if fc < fv(n)
            vk = vc; fk = fc;
            how = 'contract';
        else
            for j = 2:n
                v(:,j) = (v(:,1) + v(:,j))/2;
                x(:) = v(:,j);
                params(~mask) = x;  
		if all(params>=parmins&params<=parmaxs), fv(j) = eval(evalstr); else, fv(j)= Inf; end
            end
        cnt = cnt + n-1;
        vk = (v(:,1) + v(:,n+1))/2;
        x(:) = vk;
        params(~mask) = x; 
        if all(params>=parmins&params<=parmaxs), fk = eval(evalstr); else, fk= Inf; end
        cnt = cnt + 1;
        how = 'shrink  ';
        end
    end
    v(:,n+1) = vk;
    fv(n+1) = fk;
    [fv,j] = sort(fv);
    v = v(:,j);

    if prnt==2 & rem(cnt,100)==0
        home
        cnt
        disp(how)
        disp(' ')
        v
        fv
    end
end
x(:) = v(:,1);
if prnt==2, format, end
options(10)=cnt;    % WHAT'S THIS FOR?
options(8)=min(fv); % WHAT'S THIS FOR?
if cnt==options(5) 
    disp(['Warning: Maximum number of iterations (', ...
               int2str(options(5)),') has been exceeded']);
    disp( '         (increase OPTIONS(5)).')
end

params(~mask) = x; 	

%--------------------- SECOND PART OF WRAPPER

if all(params>=parmins&params<=parmaxs), 
	iterf = eval(evalstr); 
else 
	iterf = Inf; 
end

if prnt
	disp(['Distance is ' num2str(iterf,4) ' with parameters ' mat2str(params,2)]);
end

if iterf<=bestf, bestparams = params; bestf = iterf; end
end
params = bestparams;

%--------------------- SECOND PART OF WRAPPER ENDS HERE 

f = params;
dist = bestf;

if isnan(f), error('The parameters that are found are NaNs!'); end



