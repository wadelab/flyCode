function d = degdiff(d1,d2)
% DEGDIFF difference in degrees between two angles
%
% d = degdiff(d1,d2), where d1 and d2 are in degrees.
%
% 1999 Matteo Carandini
% part of the Matteobox toolbox

d = 180/pi*angle(exp(i*(d1-d2)*pi/180));