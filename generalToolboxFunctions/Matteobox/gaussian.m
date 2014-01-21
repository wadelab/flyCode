function [yy,xx] = gaussian(pars,xx) 
% GAUSSIAN	a gaussian 
% 
% yy = gaussian([xtop,ytop,y0,sigma],xx) 
%
% yy = gaussian(sigma,xx) assumes xtop = 0, ytop = 1, y0 = 0
%
% gaussian(sigma) assumes xx = [-round(2*sigma):round(2*sigma)]
%
% [ yy, xx ] = gaussian(...) returns also the vector xx.
%
% part of the Matteobox toolbox
%
% 1997 Matteo Carandini
% 2003-11 MC added factor of 2 in denominator
% 2006-04 MC added case for only first parameter

switch length(pars)
    case 4
        xtop 		= pars(1); % mean
        ytop 		= pars(2); % Peak max
        y0 		    = pars(3); % Offset
        sigma		= pars(4); % sigma
    case 1
        xtop 		= 0;
        ytop 		= 1;
        y0 		    = 0;
        sigma		= pars;
    otherwise
        error('Either 4 parameters or one parameter.');
end

if nargin < 2
    xx = [-round(2*sigma):round(2*sigma)];
end

yy = y0 + (ytop-y0)* exp( -(xx-xtop).^2 / (2*sigma^2) );
yy=yy(:);

