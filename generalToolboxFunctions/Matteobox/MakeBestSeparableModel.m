function [BestRow,BestCol,BestScl,BestModel,Residual] = MakeBestSeparableModel(MatrixIn,ShowGraphics);
% [BestRow,BestCol,BestScl,BestModel,Residual] = MakeBestSeparableModel(MatrixIn,ShowGraphics);
%
% This function uses singular value decomposition to obtain the best
% separable model of MatrixIn.  It returns the best row, the best column,the
% best scaling factor, the best model (bestrow*bestcol*bestscale) and the 
% residual between the best model and MatrixIn
%
% Set ShowGraphics to 1 if you'd like to see some output figures.
%
% OBSOLETE. use MakeSeparable instead.
% 03-2006 RAF wrote it.

error('MakeBestSeparableModel is obsolete.  Use MakeSeparable instead.');

if nargin<2
    ShowGraphics = 0;
end
if nargin<1
    error('MakeBestSeparableModel requires a matrix as an input.');
end

[U,S,V] = svd(MatrixIn);
BestRow = U(:,1);
BestCol = V(:,1)';
BestScl = S(1,1);
BestModel = BestRow*BestCol*BestScl;
Residual = MatrixIn - BestModel;

if ShowGraphics == 1
    lims(1,:) = [min(MatrixIn(:)) max(MatrixIn(:))];
    lims(2,:) = [min(BestModel(:)) max(BestModel(:))];
    clims = [min(lims(:,1)) max(lims(:,2))];
    figure('Color',[1 1 1]);
    subplot(1,3,1);
    imagesc(MatrixIn,clims);
    title('Original Matrix');axis tight; % axis equal;
    subplot(1,3,2);
    imagesc(BestModel,clims);
    title('Best Separable Model');axis tight; % axis equal;
    subplot(1,3,3);
    imagesc(Residual,clims);
    title('Residual');axis tight; % axis equal;
    colormap bone;
end

return

%------To test it.
ShowGraphics = 1;
FieldMat = repmat(linspace(0,1,50),50,1);
MatrixIn = randn(50,50)+2.*sin(2.*pi.*FieldMat);
[BestCol,BestRow,BestScl,BestModel,Residual] = MakeBestSeparableModel(MatrixIn,ShowGraphics);

