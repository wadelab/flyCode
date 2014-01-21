clear all;
close all;
comment='adaptation';
baseDir=uigetdir(pwd);
[a,b]=fileparts(baseDir)
bookName=[b,'_',datestr(now,30),'_',comment,'.pdf']; % We can make a pdf booklet containing printouts of our data later if we like...


phenotypeList=fly_getDataDirectories(baseDir); % This function generates the locations of all the directories..

extractionParams.freqsToExtract=[6 12]; % These are the absolute frequency values tht we will extract in Hz. 
extractionParams.freqLabels={'F1','2F1'};
extractionParams.waveformSampleRate=1000; % Hz. Resample the average waveform to this rate irrespective of the initial rate.
extractionParams.DOFLYNORM=1;

%% Here we load in all the different data files.
[phenotypeData,params]=ss_loadFlyAdaptationData(phenotypeList,extractionParams);

flyMeanWaveforms=squeeze(mean(phenotypeData{1}.meanWaveform,4));
flyMeanFT=squeeze(mean(phenotypeData{1}.normFlyExtractedData,4));
flySDFT=squeeze(std(phenotypeData{1}.normFlyExtractedData,[],4));
flySemFT=flySDFT/sqrt(size(phenotypeData{1}.normFlyExtractedData,4));
absData=abs(flyMeanFT);
%%
binToCompare=[1 2];

figure(90);
subplot(1,2,1);

hold off;

%plot(squeeze(unwrap(angle(flyMeanFT(2,[1 2],:))))');
compass(flyMeanFT(1,binToCompare(1),:),'r');
hold on;
compass(flyMeanFT(1,binToCompare(2),:),'b');
subplot(1,2,2);

hold off;

%plot(squeeze(unwrap(angle(flyMeanFT(2,[1 2],:))))');
compass(flyMeanFT(2,binToCompare(1),:),'r');
hold on;
compass(flyMeanFT(2,binToCompare(2),:),'b');
figure(1);
subplot(2,1,1);

errorbar(squeeze(absData(1,[1,2],:))',squeeze(flySemFT(1,binToCompare,:))');
legend({'1','2'});
subplot(2,1,2);

errorbar(squeeze(absData(2,[1,2],:))', squeeze(flySemFT(2,binToCompare,:))');
legend({'1','2'});


%% Work out some difference statistics. 
% We do a double comparison: (1-2)adapted - (1-2)unadapted.
contLevels=params.probeContRange;
contLevels(1)=0.01;
rawData=phenotypeData{1}.normFlyExtractedData;
diffStat1=(rawData(:,binToCompare(1),:,:)-rawData(:,binToCompare(2),:,:));  % Subtract all block 2s from all block 1s . This is pre-adaptation period - post-adaptation period
diffStat2=diffStat1(:,1,7:12,:)-diffStat1(:,1,1:6,:); % Compare these between the 80% and 0% adaptation conditions. We expect the difference to be positive if there's an effect...

% Average over flies 

meanDiff=squeeze(mean(diffStat2,4));
semDiff=squeeze(std(diffStat2,[],4))/sqrt(size(diffStat2,4));
figure(20);
h=errorbar(repmat(contLevels,2,1)',abs(meanDiff)',semDiff');
legend({'1F','2F'});
grid on;
set(gca,'XScale','Log');
title('Pre-adapt - post-adapt');

for t=1:2
    set(h(t),'LineWidth',2);
end

%%
figure(21);
h=boundedline(repmat(contLevels,2,1)',abs(meanDiff)',semDiff');
legend({'1F','2F'});
grid on;
set(gca,'XScale','Log');
title('Pre-adapt - post-adapt');




