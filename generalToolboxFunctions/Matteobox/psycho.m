function y = psycho(pars,x)
% PSYCHO the erf function rescaled bet 50% and 100%, with two parameters
%
% 	y = psycho([thresh,slope], x)
%
% 1999 Matteo Carandini and Felix Huerlimann
% part of the Matteobox toolbox

thresh = pars(1);
slope = pars(2);

% disp(['thresh is ' num2str(thresh) ' and slope is ' num2str(slope)]);

y = erf((x-thresh)*slope);

y = (((y+1)/2)*.5)+.5;


