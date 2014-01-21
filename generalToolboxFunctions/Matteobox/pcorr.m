function [ r_ab_c z_ab_c ] = pcorr( a, b, c )
% Partial correlation
% 
% r = pcorr( a, b, c ) is the correlation between a and b, once one removes
% the impact of the correlation between b and c. The inputs, a, b, and c
% must all have the same total number of elements.
%
% [r, z] = pcorr( a, b, c ) returns also the result of Fisher's
% variance-stabilizing r-to-z transform. 
%
% Note that this z value is not corrected for variance. Its standard
% deviation is sqrt(N-3), where N is the number of degrees of freedom. If
% the elements of a are indepedendent observations, then N is the number of
% elements. If not, good luck finding the right normalization.
%
% 2006-09 Matteo Carandini

cmat = corrcoef([a(:),b(:),c(:)]); 

r_ab = cmat(1,2);
r_bc = cmat(2,3);
r_ac = cmat(1,3);

r_ab_c = ( r_ab - (r_ac*r_bc) ) / sqrt((1-r_ac^2)*(1-r_bc^2));

z_ab_c = 0.5*(log(1+r_ab_c)-log(1-r_ab_c));

