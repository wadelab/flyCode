function handle= fly_plot2F1Data(meanFlyResp,semFlyResp,plotParams)


t = 3;

    crf=squeeze(meanFlyResp(t,:,:));
    sem=squeeze(semFlyResp(t,:,:));
    
%     crf =
% 
%    0.0001 - 0.0000i  -0.0001 + 0.0000i
%    0.0020 - 0.0009i   0.0014 - 0.0003i
%    0.0036 - 0.0014i   0.0027 - 0.0005i
%    0.0051 - 0.0020i   0.0039 - 0.0008i
%    0.0061 - 0.0017i   0.0053 - 0.0006i
%    0.0087 - 0.0022i   0.0063 - 0.0006i
%    0.0086 - 0.0011i   0.0066 - 0.0006i
%    0.0088 - 0.0006i   0.0072 - 0.0003i
%    0.0096 - 0.0005i   0.0075 + 0.0002i
%    0.0100 + 0.0009i   0.0080 + 0.0003i
%    0.0100 - 0.0004i   0.0087 + 0.0003i

x=100*plotParams.contRange;

% now can do the plot


figure('Name', strcat('2F1 Hz av_CRF of: ',plotParams.ptypeName));
subplot(1,2,1);
p =  errorbar (x,abs(crf(:,1)),abs(sem(:,1)));
set (p, 'color', 'red');
set (p, 'Marker', 'o');
set (p, 'MarkerFaceColor', 'red');
hold on ;
p = errorbar (x,abs(crf(:,2)),abs(sem(:,2)));
set (p, 'color', 'blue');
set (p, 'LineStyle', '--');
set (p, 'Marker', 's');
set (p, 'MarkerFaceColor', 'blue');
hold off ;

legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
set(gca,'XScale','log');
axis([0 110 0 0.005]);

xlabel('contrast (%)');
ylabel('response, a.u.');
% text( 150, 0, strjoin(myLabel) );