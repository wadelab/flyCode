function f = myxcov( a,b )
% MYXCOV Matteo's cross-covariance, with the right weights...
%
% f = myxcov( a,b )
%
% Matteo Carandini
% part of Matteobox toolbox

f = xcov( a, b, 'unbiased')/(var(a)*var(b));
