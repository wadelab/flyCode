function f = rowstd(x)
% ROWSTD takes std across rows only
%
% 	f = rowstd(x); 
%
%	it ignores the NaNs
%
% 1996,1997 Matteo Carandini
% part of the Matteobox toolbox


nrows = size(x,1);
ncols = size(x,2);

f = zeros(1,ncols);

if nrows > 1	
	if ~any(isnan(x))
		f = std(x);
	else
		for icol = 1:ncols
			notnan = find(~isnan(x(:,icol)));
			f(icol) = std(x(notnan,icol));
		end
	end
end
