function newpos = changeunits(ax,oldpos,oldunits,newunits)
% CHANGEUNITS expresses axes dims in different units
%
%		[newx, newy] = changeunits(ax,[dx dy],oldunits,newunits)
%
% 1997 Matteo Carandini
% part of the Matteobox toolbox

oldax = gca;
axes(ax);

foo = text(oldpos(1),oldpos(2),'yo!','units',oldunits);
set(foo,'visible','off');

boo = get(foo,'position');	% this is useless

set(foo,'units',newunits);
newpos = get(foo,'position');

axes(oldax);

