function f = rowmean(x)
% ROWMEAN computes the mean across rows only
%
% 	f = rowmean(x); 
%
%	it ignores the NaNs
%
% 1996,1997 Matteo Carandini
% part of the Matteobox toolbox

nrows = size(x,1);
ncols = size(x,2);

f = zeros(1,ncols);

if nrows == 1
	f = x;
else	
	if ~any(isnan(x))
		f = mean(x);
	else
		for icol = 1:ncols
			notnan = find(~isnan(x(:,icol)));
			f(icol) = mean(x(notnan,icol));
		end
	end
end
