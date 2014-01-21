function H = fillplot( x, ly, uy, c )
% FILLPLOT fill the area between two plots
%
% H = fillplot( x, ly, uy ) plots a filled graph between ly and uy, and
% returns the handles to the plot in H
%
% H = fillplot( x, ly, uy, c )
% lets you specify the color c (DEFAULT: [0.5 0.5 0.5], i.e. gray)
%
% part of the Matteobox toolbox

% 1997    Matteo Carandini 
% 2004-04 VB Graph faulty if nan as input. Nans are now discarded.
% 2006-03 MC allowed for less than 4 arguments

if nargin < 4
    c = [0.5 0.5 0.5];
end

x = x(:);
ly = ly(:);
uy = uy(:);

ind = find(isnan(ly)|isnan(uy));
x(ind) = [];ly(ind) = [];uy(ind) = [];

if length(x) ~= length(ly), error('Bad dimensions in input'); end
if length(x) ~= length(uy), error('Bad dimensions in input'); end

nx = length(x);

xx = [ x; x(nx:-1:1) ];
yy = [ ly; uy(nx:-1:1) ];
H = fill( xx, yy, c, 'EdgeColor', c );


