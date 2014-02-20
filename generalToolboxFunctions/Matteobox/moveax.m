function moveax(axlist,displacement)
% MOVEAX moves a list of axes by a given displacement
%
%	moveax(axlist,[dx dy])
%	moveax(axlist,[dx0 dy0 dxx dyy])
%
% 1998 Matteo Carandini
% part of the Matteobox toolbox

if length(displacement)~=2 & length(displacement)~=4
   error('Displacement must have 2 or 4 elements');
end

axlist = axlist(:)';

if length(displacement)== 2
   displacement = [ displacement 0 0 ];
end

for ax = axlist
   set(ax,'position',get(ax,'position')+displacement);
end

