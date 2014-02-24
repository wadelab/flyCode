function ww = robustassgn( vv, ii )
% ROBUSTASSGN robust subscript assignment (NaNs for subscripts out of range)
%
% ww = padget( vv, ii )
% is like vv(ii) but returns NaN where the ii are out of range.
%
% 2006-03 Matteo Carandini

goodones = ( ii >= 1 & ii <= length(vv) );
ww = zeros(size(ii)) * NaN;
ww(  goodones ) = vv(ii(goodones));
