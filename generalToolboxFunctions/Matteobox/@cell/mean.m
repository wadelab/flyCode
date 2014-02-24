function avg = mean( cellarray )
% MEAN
%
% Overloaded method to do a mean of cell arrays
%
% Part of Matteobox

ncells = length(cellarray);

failed = 0;

if isnumeric(cellarray{1})
    sz = size(cellarray{1});
else
    failed = 1;
end

% now should check that all entries have size sz...

if failed
    error('Not a cell array of numeric values');
end

if ~failed
    avg = zeros(sz);
    for icell = 1:ncells
        avg = avg + cellarray{icell}/ncells;
    end
end