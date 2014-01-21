function ind = findmax(vec)
% FINDMAX finds the maximum value in a vector
%
% ind = findmax(vec)
% (may return a vector if there are more than one)
%
% OBSOLETE: Use [ mx, ind ] = max(vec) instead
% 2000 Matteo Carandini
% part of the Matteobox toolbox

disp('findmax is obsolete!!! Use [ mx ind ] = max(vec) instead')

ind = find( vec(:) == max(vec(:)) );
