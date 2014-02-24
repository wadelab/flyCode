function pars = fitgeneric(xx,yy,y0,positiveflag)
% FITGENERIC fits generictune to the data
%
%	pars = fitgeneric(xx,yy) fits a generic tuning function (generictune) to the data and
%	returns the parameters pars = [xtop,ytop,ybot,sigmal,sigmar].
%
%	pars = fitgeneric(xx,yy,y0) imposes that the tuning function is y0 to the left and to 
%  the right of the data. 
%
%	pars = fitgeneric(xx,yy,y0,'positive') imposes that the tuning function be always > y0
%
% Example of use:
% 
% xx = [ 1 2 4 8 16 32];
% yy = [ 2 5 10 12 10 2 ];
% 
% plot(xx,yy,'o');
% pars = fitgeneric(xx,yy,1,'positive');
% 
% xxx = [1:32];
% hold on; plot(xxx,generictune(pars,xxx),'k-')
%
% 1997-2001 Matteo Carandini
% part of the Matteobox toolbox

if nargin<4 
   positiveflag = '';
end

xx = xx(:);
yy = yy(:);

if nargin<3
   y0_min = min(min(yy),mean(yy)-100*std(yy));
   y0_max = max(yy);
   y0_init = min(yy);
else
   y0_min = y0;
   y0_max = y0;
   y0_init = y0;
end 

deltas = diff(sort(xx)); 
% sigma_min = 1.25*min(deltas(find(deltas>0)));
sigma_min = mean(deltas(find(deltas>0))); % MC 2002-07
sigma_max = max(xx)-min(xx);

[ maxyy, indmaxyy ] = max(yy);
xtop_init = xx(indmaxyy); xtop_init = mean(xtop_init);

switch positiveflag
case 'positive'
   % ytop_min = max(y0,min(yy));
   ytop_min = max(y0,min(yy)+0.75*(max(yy)-min(yy)));
   ytop_max = max(y0,min(yy)+1.25*(max(yy)-min(yy)));
   ytop_init = max(y0,max(yy));
   [error,gausspars] = fitit(...
      'gaussian',ytop_init+max(0,yy-ytop_init),...		
      [ min(xx), ytop_min, y0_min, sigma_min ], ...		% [xtop,ytop,y0,sigma]
      [ xtop_init, ytop_init, y0_init, std(xx) ], ...
      [ max(xx), ytop_max, y0_max, sigma_max ], ...
      [0 1e-3 1e-3 3],xx);
otherwise
   % ytop_min = min(yy);
   ytop_min = min(yy)+0.75*(max(yy)-min(yy));
   ytop_max = min(yy)+1.25*(max(yy)-min(yy));
   ytop_init = max(yy);
   %---------------------------- fit a gaussian ---------------------
   [error,gausspars] = fitit(...
      'gaussian',yy,...		
      [ min(xx), ytop_min, y0_min, sigma_min ], ...		% [xtop,ytop,y0,sigma]
      [ xtop_init, ytop_init, y0_init, std(xx) ], ...
      [ max(xx), ytop_max, y0_max, sigma_max ], ...
      [0 1e-3 1e-3 3],xx);
end


% plot(xx,yy,'o',xx,gaussian(gausspars,xx),'-');

gxtop 	= gausspars(1);
gytop 	= gausspars(2);
gy0		= gausspars(3);
gsigma 	= gausspars(4);

%-------------------------- then fit a generictune ---------------------

[error,pars] = fitit(...
   'generictune',yy,...		
   [ min(xx), ytop_min, y0_min, sigma_min, sigma_min ], ...	% [xtop,ytop,ybot,sigmal,sigmar]
   [ gxtop, gytop, gy0, gsigma, gsigma ], ...
   [ max(xx), ytop_max, y0_max, sigma_max, sigma_max ], ...
   [0 1e-4 1e-3 10],xx);

% plot(xx,yy,'o',xx,generictune(pars,xx),'-');

%------------------------------------------------------------------------

if pars(2)==pars(3) % if ytop == ybot
   pars([1 4 5]) = NaN; % these 3 parameters make no sense
end

