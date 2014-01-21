function f = rowmean(x)
% ROWSEM standard error of the mean across rows only
%
% 	f = rowsem(x); 
%
%	it ignores the NaNs
%
% 1997 Matteo Carandini
% part of the Matteobox toolbox

nrows = size(x,1);
ncols = size(x,2);

f = zeros(1,ncols);

if nrows > 1	
	if ~any(isnan(x))
		f = sem(x);
	else
		for icol = 1:ncols
			notnan = find(~isnan(x(:,icol)));
			f(icol) = sem(x(notnan,icol));
		end
	end
end
