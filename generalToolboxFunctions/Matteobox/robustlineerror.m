function err = robustlineerror(ab,xx,yy,d)
% ROBUSTLINEERROR is used by fitline to compute robust fits
%
% 1998 Matteo Carandini
% part of the Matteobox toolbox


sqdists = (ab(1)*xx+ab(2)-yy).^2;

sqdists(sqdists>(d^2))=d^2;

err = nansum( sqdists );