function [BestCol,BestRow,BestScl,BestModel,Residual] = MakeSeparable(MatrixIn,ShowGraphics);
% MakeSeparable finds the best separable approximation to a matrix
% 
%[BestRow,BestCol,BestScl,BestModel,Residual] = MakeSeparable(MatrixIn,ShowGraphics);
%
%This function uses singular value decomposition to obtain the best
%separable model of MatrixIn.  It returns the best row, the best column,the
%best scaling factor, the best model (bestrow*bestcol*bestscale) and the 
%residual between the best model and MatrixIn
%
%Originally called MakeBestSeparableModel
%
%Set ShowGraphics to 1 if you'd like to see some output figures.
%
%03-2006 RAF wrote it.
%05-2006 RAF added the eigenspectrum as an output

if nargin<2
    ShowGraphics = 0;
end
if nargin<1
    error('MakeSeparable requires a matrix as an input.');
end

[U,S,V] = svd(MatrixIn,'econ');
BestRow = U(:,1);
BestCol = V(:,1)';
BestScl = S(1,1);
BestModel = BestRow*BestCol*BestScl;
Residual = MatrixIn - BestModel;

if ShowGraphics == 1
    %1st principal Component figure
    lims(1,:) = [min(MatrixIn(:)) max(MatrixIn(:))];
    lims(2,:) = [min(BestModel(:)) max(BestModel(:))];
    lims(3,:) = [min(Residual(:)) max(Residual(:))];
    clims = [min(lims(:,1)) max(lims(:,2))];
    figure('Color',[1 1 1]);
    subplot(1,3,1);
    imagesc(MatrixIn,clims);
    title('Original Matrix');axis equal;axis tight;
    subplot(1,3,2);
    imagesc(BestModel,clims);
    title('Best Separable Model');axis equal;axis tight;
    subplot(1,3,3);
    imagesc(Residual,clims);
    title('Residual');axis equal;axis tight;
    colormap bone;
    
    %Eigenspectrum figure
    PC = linspace(1,size(S,1),size(S,1));
    for il = 1:size(S,1)
        VarAccount(il) = S(il,il)./sum(S(:));
    end
    CumAccount = cumsum(VarAccount);
    figure('Color',[1 1 1]);
    stem(PC,VarAccount);hold on;plot(PC,CumAccount,'r-');
    title('Eigenspectrum');
    xlabel('Principal Component #');
    ylabel('% Variance accounted');
    legend('Individual','Cumulative');
end

return

%------To test it.
ShowGraphics = 1;
FieldMat = repmat(linspace(0,1,50),50,1);
MatrixIn = randn(50,50)+10.*sin(2.*pi.*FieldMat);
[BestCol,BestRow,BestScl,BestModel,Residual] = MakeBestSeparableModel(MatrixIn,ShowGraphics);

