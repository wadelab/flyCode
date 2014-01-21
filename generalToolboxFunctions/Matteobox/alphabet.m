function f = alphabet(ii)
% ALPHABET useful for labels
%
% 1996 Matteo Carandini
% part of the Matteobox toolbox

f = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

if nargin == 1, 
	f = f(ii);
end
