function y = nansem( x, flag, dim )
% Originally from Matteobox
% $Author$
if nargin<3
    dim = [];
end

if nargin<2
    flag = [];
end

n =  sum( ~isnan(x), dim );
y = nanstd( x, flag, dim ) ./ sqrt(n-1);

