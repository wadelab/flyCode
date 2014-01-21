function ax = gridplot(nrows, ncols, irow, icol)
% GRIDPLOT a smarter version of subplot
%
% ax = gridplot(nrows, ncols, irow, icol)
% places a subplot at irow, icol in a grid of nrows, ncols.
% Also takes care of the "align" flag that suddenly was required in Matlab
% version 7.
% 
% Part of Matteobox
% See also SUBPLOT
%
% 2005-09 MC

if irow>nrows | icol>ncols
    error('inconsistent inputs');
end

iax = icol+(irow-1)*ncols;

% actually I am not sure the instruction "version" existed before Matlab 7
% also, I am assuming the "align" hassle started with release 14.

if version('-release') >= 14
    ax = subplot( nrows, ncols, iax, 'align' );
else
    ax = subplot( nrows, ncols, iax);
end
