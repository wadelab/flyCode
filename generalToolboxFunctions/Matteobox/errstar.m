function errstar(x,y,ex,ey,varargin)
% ERRSTAR plots a series of points with errors in x and y
%
%	errstar(x,y,ex,ey,varargin)
%
% 1998 Matteo Carandini
% part of the Matteobox toolbox

x = x(:);
y = y(:);

n = length(x);
if length(y)~=n
   error('boo');
end

ex(find(isnan(ex)))=0;
ey(find(isnan(ey)))=0;

for ii = 1:length(x)
   plot( x(ii)+ex(ii)*[ 0 1], y(ii)*[1 1], 'k-' ); hold on
   plot( x(ii)+ex(ii)*[-1 0], y(ii)*[1 1], 'k-' ); 
   plot( x(ii)*[1 1], y(ii)+ey(ii)*[-1 0], 'k-' );
   plot( x(ii)*[1 1], y(ii)+ey(ii)*[ 0 1], 'k-' );
end
plot(x,y,varargin{:});
