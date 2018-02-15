read_arduino_tree();

t=0:4:4092 ;

figure;
i = 1;
for f = 1:3
    
    r=Collected_Data(f).sortedRawData ;
    s=Collected_Data(f).sortedStimData ;
    
    for k = [14 24 39]
        subplot(3,3,i);
        i=i+1 ;
        [AX, H1, H2] = plotyy (t,r(k,:),t,s(k,:));
        set(AX(1), 'XLim', [0 2048]);
        set(AX(1), 'YLim', [-250 500]);
        set(AX(2), 'XLim', [0 2048]);
        set(AX(2), 'YLim', [-1200 700]);
        %axis([0 2048 -600 1000]);
    end
end
