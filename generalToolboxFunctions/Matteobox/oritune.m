function f = oritune(pars,oris) 
% ORITUNE 	sum of two gaussians living on a circle, for orientation tuning
% 
%		oritune([Dp, Rp, Rn, Ro, sigma], oris), where
%		Dp is the preferred direction (bet 0 and 360)
%		Rp is the response to the preferred direction;
%		Rn is the response to the opposite direction;
%		Ro is the background response (useful only in some cases)
%		sigma is the tuning width;
% 		oris are the orientations, bet 0 and 360.
%
%		oritune([Dp, Rp, Rn, Ro, sigma], 'spiel'), gives you a little description of the tuning.
%
% 1997-1998 Matteo Carandini
% part of the Matteobox toolbox

if length(pars(:))~= 5
   error('You must specify all 5 parameters');
end

Dp = pars(1); Rp = pars(2); Rn = pars(3); Ro = pars(4); sigma = pars(5);

if ischar(oris) & strcmp(oris,'spiel')
   disp(['Width at half height is ' num2str(sqrt(log(2)*2)*sigma,3) ' deg']);
   disp(['Direction index is ' num2str((Rp-Rn)/(Rp+Rn),3)]);
else
   anglesp = 180/pi*angle(exp(i*(oris-Dp)    *pi/180));
   anglesn = 180/pi*angle(exp(i*(oris-Dp+180)*pi/180));
   
   f = Ro +...
      Rp*	exp( -anglesp.^2 ./ (2 * sigma^2)) + ...
      Rn*	exp( -anglesn.^2 ./ (2 * sigma^2));
end
