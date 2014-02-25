function handle= fly_plotPolarData(meanFlyResp,semFlyResp,plotParams)
% handles= fly_plotCartData(meanFlyResp{thisPhenotype},semFlyResp{thisPhenotype},plotParams)
% Plots data from a fly sserg experiment in cartesian coordinates.
% Returns a vector of handles to the plots of the different experiments.


 for t=1:size(meanFlyResp,1) % Different frequencies
     % We assume that there are two mask conditions. But this should really
     % be more flexible...
        subplot(plotParams.subplotDims(1),plotParams.subplotDims(2),plotParams.subPlotIndices(t)); % 
      
        crf=squeeze(meanFlyResp(t,:,:));
        hold off;
        % Plot a dummy function to set the scale
        theta  = linspace(0,2*pi,100);
        r      = sin(2*theta) .* cos(2*theta);
        r_max  = plotParams.polarLims(t);
        h_fake = polar(theta,r_max*ones(size(theta)));
        set(h_fake,'Color',[1 1 1]);
        
        hold on;
        %%
        
          handle(1,:)=compass(real(crf(:,1)),imag(crf(:,1)),'k');
        
        
        
        for th=1:length(handle(1,:))
            set(handle(1,th),'Color',[0.6,0.6 ,0.6]-0.05*th);
            set(handle(1,th),'LineWidth',plotParams.lineWidthPolar);
            a = get(handle(1,th), 'xdata');  % Get rid of arrows. Thanks StackOverflow!
            b = get(handle(1,th), 'ydata');
            set(handle(1,th), 'xdata', a(1:2), 'ydata', b(1:2))
            if (plotParams.DO_ERRORCIRCS)
                
                x=get(handle(1,th),'XData');
                y=get(handle(1,th),'YData');
                rad=abs(semFlyResp(t,th,1));
                xPos=rad*cos(linspace(0,2*pi,30))+x(2);
                yPos=rad*sin(linspace(0,2*pi,30))+y(2);
                p(t,th,1)=patch(xPos,yPos,'r');
                set(p(t,th,1),'FaceAlpha',0.02);
                set(p(t,th,1),'FaceColor',[0.6 0.6 0.6]-0.05*th);
                
            end
                        
            
            
        end
        hold on;
       
        %%
        handle(2,:)=compass(real(crf(:,2)),imag(crf(:,2)),'r');
        set(gca,'FontSize',8);
        
        for th=1:length(handle(2,:))
            set(handle(2,th),'Color',[1 0.6 0.6]-0.05*th);
            set(handle(2,th),'LineWidth',plotParams.lineWidthPolar);
            a = get(handle(2,th), 'xdata');  % Get rid of arrows. Thanks StackOverflow!
            b = get(handle(2,th), 'ydata'); 
            set(handle(2,th), 'xdata', a(1:2), 'ydata', b(1:2))
            
            if (plotParams.DO_ERRORCIRCS)
                
            x=get(handle(2,th),'XData');
            y=get(handle(2,th),'YData');
            rad=abs(semFlyResp(t,th,2));
            xPos=rad*cos(linspace(0,2*pi,30))+x(2);
            yPos=rad*sin(linspace(0,2*pi,30))+y(2);
            p(t,th,2)=patch(xPos,yPos,'r');
            set(p(t,th,2),'FaceAlpha',0.02);
            set(p(t,th,2),'FaceColor',[1 0.6 0.6]-0.05*th);
            end
            
            
        end
        %%
  
       

        
        th = findall(gcf,'Type','text');
        
        %%%%%%%%%%%%%% do we really want this ???
        %         for i = 1:length(th),
        %             set(th(i),'FontSize',6)
        %         end
        set(gca,'FontSize',12);
        if (t==1)
            title(sprintf('%s\n%s',plotParams.ptypeName, plotParams.labelList{t}));
        else
            title(sprintf('\n%s', plotParams.labelList{t}));
        end
        
        
 end
 
 return;
  
 
 % NB add error xircles like this:
 radius = 0.5;
centerX = 0.5;
centerY = 0,5;

angleRange=0:0.1:2*pi
x=radius*cos(angleRange)+centerX;
y=radius*sin(angleRange)+centerY;


p=patch(x,y,'r');
  set(p,'FaceAlpha',0.2);