function itslog  =  islogspaced(xx)
% ISLOGSPACED	determines if a vector is log spaced or linear
%
%		islogspaced(xx)
%
%		It is smart about approx spacings. 
%
% 1997 Matteo Carandini
% 2002-02 MC fixed so it can deal with negative numbers
% 2003-03 MC fixed so it can deal with vectors with identical members
%
% part of the Matteobox toolbox

%--------- let's be pessimistic and assume it is not log spaced
itslog = 0;

if any(xx<0), return; end

xx(find(xx==0)) = [];

if isempty(xx), return; end

if length(unique(xx))<=2, return; end

linspaces = diff(unique(xx));
logspaces = diff(unique(log(xx)));

if std(logspaces)/mean(logspaces) < std(linspaces)/mean(linspaces)
	itslog = 1;
end

