function h = sidetitle(ax, strtitle)
% SIDETITLE places a title on the right side of an axes object
% 
% h = sidetitle( s ) places the title s on the right side of the current axes
% object. returns handle h to text object.
%
% sidetitle( ax, s ) lets you specify the axes object
%
% part of matteobox
%
% 2003-11 Matteo Carandini
% 2004-11 VB returns handle. 

if nargin < 2, strtitle = ax; ax = gca; end

oldax = gca;

axes(ax);

h = text(1,0.5,strtitle,'units','norm','hori','left','vert','middle');

axes(oldax);