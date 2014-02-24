function y = sem(x)
%SEM	Standard error of the mean.
%	For vectors, SEM(x) returns the standard error of the mean.
%	For matrices, SEM(X) is a row vector containing the
%	standard error of the mean of each column.
%
%	STD computes the "sample" standard deviation, that
%	is, it is normalized by N-1, where N is the sequence
%	length.
%
%	See also STD, COV, MEAN, MEDIAN.

% 1996 Matteo Carandini
% part of the Matteobox toolbox

[m,n] = size(x);
if (m == 1) + (n == 1)
    m = max(m,n);
    y = norm(x-sum(x)/m);
else
    avg = sum(x)/m;
    y = zeros(size(avg));
    for i=1:n
        y(i) = norm(x(:,i)-avg(i));
    end
end
if m == 1
    y = 0;
else 
    y = y / sqrt(m*(m-1));
end
