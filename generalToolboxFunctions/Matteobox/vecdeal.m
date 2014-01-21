function varargout = vecdeal(vv)
% VECDEAL deals a vector to a comma-separated list of variable names
%
% [a,b,c] = vecdeal([1 2 3]) results in a = 1; b = 2; c = 3;
%
% 2006-08 Matteo Carandini

nv = length(vv);

if nargout ~= nv
    error('Wrong number of outputs');
end

for iv = 1:nv
    varargout(iv) = {vv(iv)};
end
