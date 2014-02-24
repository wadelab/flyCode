function pars = fitori( oo, rr, ss, fixedpars )
% FITORI fit orientation tuning data with oritune curve
% 
%		syntax is pars = fitori(oo,rr), where oo are the orientations,
%		rr are the responses, and pars = [Dp, Rp, Rn, Ro, sigma];
%
%		fitori(xx) assumes oo = xx(1,:) and rr = xx(2,:)
% 
%		fitori(oo,rr,ss) lets you specify the standard deviations ss
%		(default: [])
%
%		fitori(oo,rr,ss,fixedpars) lets you specify the value of certain
%		parameters (put NaN if you don't want to specify). 
%
%       SEE ALSO: oritune

% 1997 Matteo Carandini
% 1999 Matteo Carandini, corrected pref ori bias
% part of the Matteobox toolbox

if nargin == 1,
   oo = oo(1,:);
	rr = oo(2,:);
end

if nargin <3 || isempty(ss)
   ss = zeros(size(rr)); 
end

if nargin<4, fixedpars = [ NaN NaN NaN NaN NaN ]; end

oo = oo(:);
rr = rr(:);
ss = ss(:);

if any(size(oo)~=size(rr)),
	error('oo and rr have different sizes');
end

if ~any(rr)
	err = 0;
	pars = [ NaN 0 0 0 NaN ];
	return
end

%---------------- make all the rr be>0

minrr = min(rr);
rr = rr-minrr;

%----------------  preferred ori

if isnan(fixedpars(1)) 
   xx = rr.*cos(oo*pi/180);
   yy = rr.*sin(oo*pi/180);
   a1 = xx(:)\yy(:);
   a2 = yy(:)\xx(:);
   err1 = norm(yy-a1*xx);
   err2 = norm(xx-a2*yy);
   if err2 < err1
       prefori = 180/pi*atan(1/a2);
   else
       prefori = 180/pi*atan(a1);
   end
   minprefori	= -180;
   maxprefori	=  180;

else
   prefori      = fixedpars(1);
   minprefori	= fixedpars(1);
   maxprefori	= fixedpars(1);
end

% plot(xx,a1*xx,'--',a2*yy,yy,'-',xx,yy,'o');
% set(gca,'dataaspectratio',[1 1 1]);

diffangles = abs(angle(exp(i*(oo-prefori)*pi/180)));

%----------------  resp to pref ori

if isnan(fixedpars(2))
   rp 		= mean(rr(find(diffangles==min(diffangles))));
   minrp 	= 0;
   maxrp 	= max(rr);
else
   rp 		= fixedpars(2);
   minrp	= fixedpars(2);
   maxrp	= fixedpars(2);
end

%---------------- resp to null ori

if isnan(fixedpars(3))
   rn 		= mean(rr(find(diffangles==max(diffangles))));
   minrn 	= 0;
   maxrn 	= max(rr);
else
   rn 		= fixedpars(3);
   minrn	= fixedpars(3);
   maxrn	= fixedpars(3);
end

%--------------- min resp

if isnan(fixedpars(4))
   r0 		= 0;
   minr0 	= -max(rr)/5; %  allow mildly negative baselines
   maxr0 	= max(rr);
else
   r0 		= fixedpars(4)-minrr;
   minr0	= fixedpars(4)-minrr;
   maxr0	= fixedpars(4)-minrr;
end

%--------------- tuning width sigma

if isnan(fixedpars(5))
   minsigma 	= min(diff(unique(oo)))/2;	% 1/2 spacing bet samples
   maxsigma 	= 80;
   sigmas = minsigma:3:maxsigma;
   errs = zeros(size(sigmas));
   for isigma = 1:length(sigmas)
   	errs(isigma) = norm( oritune([prefori rp rn r0 sigmas(isigma)],oo)-rr )^2; 
   end            
	sigma = sigmas(find(sigmas==min(sigmas)));
else
   sigma	= fixedpars(5);
   minsigma	= fixedpars(5);
   maxsigma	= fixedpars(5);
end

               
%---------------------------- finally, do the fit -------------------------

[ err, pars ] = fitit(  'oritune', rr,...
						[ minprefori minrp minrn minr0 minsigma ],...
						[    prefori    rp    rn    r0    sigma ],...
						[ maxprefori maxrp maxrn maxr0 maxsigma ],...
						[0 1e-4 1e-4 5 400 1], oo, ss );
                    
% [err,pars,exitflag,output] = lsqfit(  'oritune', rr,...
% 						[ -180 minrp minrn minr0 minsigma ],...
% 						[ prefori    rp    rn    r0    sigma ],...
% 						[ 180 maxrp maxrn maxr0 maxsigma ],...
% 						[], oo, ss );
               
% add minrr back to the pars:
pars(4) = pars(4)+minrr;              
               
% rr = rr + minrr              
% plot( oo, rr, 'o', 0:360, oritune(pars,0:360), '-' )

%-------------------------- make sure Rp is bigger than Rn -------------------

pp = num2cell(pars);
[Dp, Rp, Rn, Ro, sigma] = deal(pp{:});

if Rp<Rn 
   Dp = mod(Dp+180,360);
   [Rp, Rn] = deal(Rn, Rp);
end

pars = [Dp, Rp, Rn, Ro, sigma];
