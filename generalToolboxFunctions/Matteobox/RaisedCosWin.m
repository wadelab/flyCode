function ww = RaisedCosWin(nt,exponent)
% RaisedCosWin a raised cosine window useful for filtering
%
% ww = RaisedCosWin(nt)
%
% ww = RaisedCosWin(nt,exponent) lets you specify the exponent (DEFAULT:
% 0.3)

if nargin<2
    exponent = 0.3;
end

ww = cos(([0:(nt-1)] -(nt-1)/2)/(nt-1)*pi).^exponent;
