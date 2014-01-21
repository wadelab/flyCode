function f = phase(x)
% PHASE a smart measure of complex number phase
%
%		Works just as ANGLE, except that it returns NaN 
%		where the argument is 0
%
% 1996 Matteo Carandini
% part of the Matteobox toolbox

suckers = find(x==0);

f = angle(x); f(suckers) = ones(size(suckers)) * NaN;
