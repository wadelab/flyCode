function handle= fly_plotCartData(meanFlyResp,semFlyResp,plotParams)
% handles= fly_plotCartData(meanFlyResp{thisPhenotype},semFlyResp{thisPhenotype},plotParams)
% Plots data from a fly sserg experiment in cartesian coordinates.
% Returns a vector of handles to the plots of the different experiments.
if (~isfield(plotParams,'errorEnvelope'))
    plotParams.errorEnvelope=1;
end
if (~isfield(plotParams,'XAxisType'))
    plotParams.XAxisType='Log';
end

nMaskConds=size(meanFlyResp,3);

for t=1:size(meanFlyResp,1) % Different frequencies
    % We assume that there are two mask conditions. But this should really
    % be more flexible...
    crf=squeeze(meanFlyResp(t,:,:));
    sem=squeeze(semFlyResp(t,:,:));
    subplot(plotParams.subplotDims(1),plotParams.subplotDims(2),plotParams.subPlotIndices(t)); %
    hold off;
    % Check the first value of contRange. If it's zero, plot zero
    % separately and break the line.
    if (plotParams.contRange(1)~=0) % Do we have a 0 in the contrast range?
        
        if (plotParams.errorEnvelope==0)
            handle(1)=errorbar(plotParams.contRange,abs(crf(:,1)),sem(:,1));
            set(handle(1),'LineWidth',plotParams.lineWidthCart);
            set(handle(1),'Color',[0.2 0.2 0.2]);
            
            hold on;
            
        else
            handle(1)=boundedline(plotParams.contRange,abs(crf(:,1)),sem(:,1));
            set(handle(1),'LineWidth',plotParams.lineWidthCart);
            set(handle(1),'Color',[0.2 0.2 0.2]);
            
            hold on;
        end
        
        
        set(handle(2),'Color',[0.4 0.4 0.4]);
        set(handle(2),'LineWidth',plotParams.lineWidthCart);
        grid on;
        axis square
        set(handle(1),'FontSize',12);
        
        
            
        set(gca,'XScale',plotParams.XAxisType);     
        set(gca,'FontSize',12);
   
        xlabel('Probe Contrast','FontSize',14);
        ylabel('Resp amplitude','FontSize',14);
        
        if (plotParams.maxYLim(t)~=0)
            set(gca,'YLim',[0 plotParams.maxYLim(t)]);
        end
        
        set(gca,'XLim',[0 0.8]);
        title(sprintf('%s\n%s',plotParams.ptypeName, plotParams.labelList{t}),'FontSize',14);
        
        
        
    else % If zero does  appear in the contrast range we have to treat it separately.
        zeroPoint=plotParams.contRange(2)/2;
        
        hold off;
        if (nMaskConds==1)
            crf=crf(:);
            sem=sem(:);
        end
        
        if (plotParams.errorEnvelope==0) % Are we plotting error bars or error envelopes?
            handle(1)=errorbar(plotParams.contRange(2:end),abs(crf((2:end),1)),sem((2:end),1));
            set(handle(1),'LineWidth',plotParams.lineWidthCart);
            set(handle(1),'Color',[0.2 0.2 0.2]);
            
            hold on;
            
        else
            
            [ handle(1),patch(1)]=boundedline(plotParams.contRange(2:end),abs(crf((2:end),1)),sem((2:end),1));
            set(handle(1),'LineWidth',plotParams.lineWidthCart);
            set(handle(1),'Color',[0.2 0.2 0.2]);
            set(patch(1),'FaceColor',[0.7 0.7 0.7]);
            set(patch(1),'FaceAlpha',0.2);
            
            hold on;
        end
        
        
        if (nMaskConds==2)
            hold on;
            handle(3)=errorbar(zeroPoint,abs(crf((1),1)),sem((1),1));
            
            set(handle(1),'LineWidth',plotParams.lineWidthCart);
            set(handle(1),'Color',[0.2 0.2 0.2]);
            set(handle(3),'LineWidth',plotParams.lineWidthCart);
            set(handle(3),'Color',[0.2 0.2 0.2]);
            
            
            if (plotParams.errorEnvelope==0)
                handle(2)=errorbar(plotParams.contRange(2:end),abs(crf((2:end),2)),sem((2:end),2));
                set(handle(2),'LineWidth',plotParams.lineWidthCart);
                set(handle(2),'Color',[0.0 0.0 0.0]);
                
                hold on;
                
            else
                [ handle(2),patch(2)]=boundedline(plotParams.contRange(2:end),abs(crf((2:end),2)),sem((2:end),2));
                set(handle(2),'LineWidth',plotParams.lineWidthCart);
                set(handle(2),'Color',[0.0 0.0 0.0]);
                set(patch(2),'FaceColor',[0.7 0.5 0.5]);
                
                hold on;
            end
            
            handle(4)=errorbar(zeroPoint,abs(crf((1),2)),sem((1),2));
            
            set(handle(2),'Color',[0.4 0.4 0.4]);
            set(handle(2),'LineWidth',plotParams.lineWidthCart);
            
            set(handle(4),'Color',[0.4 0.4 0.4]);
            set(handle(4),'LineWidth',plotParams.lineWidthCart);
        end
        
        grid on;
        axis square
        
        
 set(gca,'XScale',plotParams.XAxisType); 
 set(gca,'FontSize',12);
   
        xlabel('Probe Contrast','FontSize',14);
        ylabel('Resp amplitude','FontSize',14);
        if (plotParams.maxYLim(t)~=0)
            set(gca,'YLim',[0 plotParams.maxYLim(t)]);
        end
        
        set(gca,'XLim',[0 0.8]);
        if (t==1)
            title(sprintf('%s\n%s',plotParams.ptypeName, plotParams.labelList{t}),'FontSize',14);
        end    
    end
    
    
end
%fname=sprintf('%s_CART',plotParams.ptypeName);

%print('-depsc', fname);
