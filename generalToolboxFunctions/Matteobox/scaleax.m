function scaleax(axlist,scalelist)
% SCALEAX scales a list of axes by a given factor
%
%	scaleax(axlist,[xsc ysc])
%	scaleax(axlist,sc)

% 2006 Matteo Carandini
% part of the Matteobox toolbox

if length(scalelist) < 2 
    scalelist = [ scalelist scalelist ];
end

axlist = axlist(:)';

for ax = axlist
    pp = get(ax,'position');
    cc = [ pp(1)+pp(3)/2, pp(2)+ pp(4)/2 ];
    nn(3) = pp(3)*scalelist(1);
    nn(4) = pp(4)*scalelist(2);
    nn(1) = cc(1) - nn(3)/2;
    nn(2) = cc(2) - nn(4)/2;
    set(ax,'position', nn );
end

return

%------------------------------------
%       code to test the function

figure; clf; ax = []; cax = [];
for irow = 1:5
    for icol = 1:5
        ax(irow,icol) = gridplot(5,5,irow,icol);
        imagesc( peaks );
        cax(irow,icol) = colorbar;
    end
end
set(ax,'dataaspectratio',[1 1 1]);

scaleax(cax(1:5),[0.5 2])
moveax(cax,[+0.01 0])