function plot_mean_crf (myLabel, complx_CRF, pathstr, fileName, bCloseGraphs, varargin)

% variable argument is the error bars...

if (nargin < 6)
    % missing error bars
    eb = zeros(size(complx_CRF));
    ymax(1:9) = inf;
else
    eb = varargin{1};
    ymax = varargin{2};
end

FreqNames = GetFreqNames();
sExt = getPictExt () ;

%% plot the fft data for this fly...
%[theta_CRF,abs_CRF] = cart2pol(real(complx_CRF(:,:)), imag(complx_CRF(:,:)))
theta_CRF=angle(complx_CRF);
abs_CRF = abs(complx_CRF);
eb_CRF = abs(eb) ;

% how many unmasked contrasts were given
nUnMasked = sum(abs_CRF(:,1)==0) ;
[dummy, nContrasts] = size (abs_CRF);


%return the data
thisFlyData.nUnMasked = nUnMasked ;


%% everything here is a plot so we get pictures in the directory where the file was

disp (['File ok: ', fileName])

%     mask %    contrast   12Hz  & 15 Hz       24  &   30 Hz      F1+F2    2F1_2F2 response
%          0    0.0050    0.7000    0.1192    0.0682    0.1184    0.0602    0.0088
%          0    0.0100    1.1445    0.1962    0.0290    0.0976    0.0798    0.1139
%          0    0.0300    3.4122    0.0642    0.1332    0.0834    0.1172    0.1681
%          0    0.0700    7.7857    0.0965    0.3987    0.0752    0.1233    0.1432
%          0    0.1000    9.8932    0.1163    0.5891    0.1674    0.2707    0.0640
%     0.0300    0.0050    0.4410    2.4871    0.1067    0.1131    0.1026    0.0233
%     0.0300    0.0100    0.9691    2.4725    0.1457    0.2365    0.1073    0.1004
%     0.0300    0.0300    3.3535    2.5891    0.0647    0.1302    0.1800    0.0678
%     0.0300    0.0700    6.8394    2.6980    0.2947    0.1872    0.5111    0.131



%% Plot 12 Hz CRF for this fly

figure('Name', strcat('1F1 Hz CRF of: ',fileName));
subplot(1,2,1);

p = errorbar (abs_CRF([1:nUnMasked],2), abs_CRF([1:nUnMasked],3), eb_CRF([1:nUnMasked],3)) ;
set (p, 'color', 'red');
set (p, 'Marker', 'o');
set (p, 'MarkerFaceColor', 'red');
hold on ;
p = errorbar (abs_CRF([nUnMasked+1:nContrasts],2), abs_CRF([nUnMasked+1:nContrasts],3), eb_CRF([nUnMasked+1:nContrasts],3));
set (p, 'color', 'blue');
set (p, 'Marker', 's');
set (p, 'MarkerFaceColor', 'blue');
hold off ;



legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
set(gca,'XScale','log');
axis([0 110 0 ymax(3)]);

xlabel('contrast (%)');
ylabel('response, a.u.');
text( 150, 0, strjoin(myLabel) );
subplot(1,2,2);

polar (theta_CRF(1:nUnMasked,3),abs_CRF(1:nUnMasked,3), '-*');
hold on ;
polar (theta_CRF(nUnMasked+1:end,3),abs_CRF(nUnMasked+1:end,3), '--Om');
hold off;

% move picture to left
myPos = get(gcf, 'Position');
myPos(1) = myPos (1) -  myPos (3)/2 ;
set(gcf, 'Position', myPos );


printFilename = [pathstr, filesep, fileName, '_', FreqNames{1}, '_CRF', sExt];
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print( printFilename );
if (bCloseGraphs)
    delete(gcf) ;
end

%% Plot 24 Hz av_CRF for this fly

figure('Name', strcat('2F1 Hz av_CRF of: ',fileName));
subplot(1,2,1);
p = errorbar (abs_CRF([1:nUnMasked],2), abs_CRF([1:nUnMasked],5), eb_CRF([1:nUnMasked],5)) ;
set (p, 'color', 'red');
set (p, 'Marker', 'o');
set (p, 'MarkerFaceColor', 'red');
hold on ;
p = errorbar (abs_CRF([nUnMasked+1:nContrasts],2), abs_CRF([nUnMasked+1:nContrasts],5), eb_CRF([nUnMasked+1:nContrasts],5));
set (p, 'color', 'blue');
set (p, 'Marker', 's');
set (p, 'MarkerFaceColor', 'blue');
hold off ;

legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
set(gca,'XScale','log');
axis([0 110 0 ymax(5)]);

xlabel('contrast (%)');
ylabel('response, a.u.');
text( 150, 0, strjoin(myLabel) );

subplot(1,2,2);
%[t,r] = cart2pol(real(complx_CRF(:,5)), imag(complx_CRF(:,5)));
polar (theta_CRF(1:nUnMasked,5),abs_CRF(1:nUnMasked,5), '-*');
hold on ;
polar (theta_CRF(nUnMasked+1:end,5),abs_CRF(nUnMasked+1:end,5), '--Om');
hold off;

% move picture to right
myPos = get(gcf, 'Position');
myPos(1) = myPos (1) +  myPos (3)/2 ;
set(gcf, 'Position', myPos );

printFilename = [pathstr, filesep, fileName, '_', FreqNames{3}, '_CRF', sExt];
print( printFilename );
if (bCloseGraphs)
    delete(gcf) ;
end

