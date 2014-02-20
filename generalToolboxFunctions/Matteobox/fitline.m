function [ a, b, estsema ] = fitline( abscissa, ordinate, outlierdist )
% FITLINE fits a line to the data
%
%	[ a, b ] = fitline( abscissa, ordinate )
%	gives a and b such that a abscissa + b approximates ordinate 
%
%	[ a, b, estsema ] = fitline( abscissa, ordinate )
%	also gives you the estimated standard error of the slope a 
%
%	[ a, b ] = fitline( abscissa, ordinate, outlierdist )
%	is for robust estimation: it ignores points more than outlierdist from the line 
%
%	pred = fitline( abscissa, ordinate ) 
%	gives the predicted ordinate obtained from the fit.
%
%	if there are NaNs in the ordinate, it ignores them
%
% 1995, 1998 Matteo Carandini
% 2003 MC updated with fminsearch
%
% part of the Matteobox toolbox

abscissa = abscissa(:);
ordinate = ordinate(:);

if length(abscissa)~=length(ordinate)
    error('Abscissa and ordinate must have same length');
end

notnans = find(~isnan(ordinate));
xx = abscissa(notnans);
yy = ordinate(notnans);

if length(xx)<=2
    pars = [ NaN; NaN ];
else
    pars = [ xx, ones(size(xx)) ] \ yy;
end

if nargout ==1,
    a = [ abscissa, ones(size(abscissa)) ] * pars;
else
    a = pars(1); b = pars(2);
end

if nargout == 3
    n = length(xx);
    foo = corrcoef(xx,yy);
    r = foo(1,2);
    estsema = var(yy)/var(xx)*(1-r^2)/(n-2);
end

if nargin == 3 && outlierdist>0 && outlierdist<inf
    
    strVersion = version;
    iMatlabVersion = str2num(strVersion(1));
    
    if iMatlabVersion>5
        ab = fminsearch( 'robustlineerror', [ a b ], [], abscissa, ordinate, outlierdist );
    else
        ab = fmins( 'robustlineerror', [ a b ], [], [], abscissa, ordinate, outlierdist );
    end
    a = ab(1);
    b = ab(2);
    % robustlineerror([a b],	abscissa, ordinate,outlierdist)
    % robustlineerror(ab,		abscissa, ordinate,outlierdist)
end

