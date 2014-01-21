clear all;
close all;
%% Initialisation of POI Libs
% Add Java POI Libs to matlab javapath
 a='/data_biology/SSERG/toolbox/xlwrite/';
javaaddpath(fullfile(a,'poi_library/poi-3.8-20120326.jar'));
javaaddpath(fullfile(a,'poi_library/poi-ooxml-3.8-20120326.jar'));
javaaddpath(fullfile(a,'poi_library/poi-ooxml-schemas-3.8-20120326.jar'));
javaaddpath(fullfile(a,'poi_library/xmlbeans-2.3.0.jar'));
javaaddpath(fullfile(a,'poi_library/dom4j-1.6.1.jar'));
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


nPhenotypes=length(phenotypeList)
%%
close all;
for thisPhenotype=1:nPhenotypes
%     Using normalized values here gives you a nice percentage change
%     measure. But it obscures the absolute magnitudes of the data
%     flyMeanWaveforms=squeeze(mean(phenotypeData{thisPhenotype}.meanWaveform,4));
%     flyMeanFT=squeeze(mean(phenotypeData{thisPhenotype}.normFlyExtractedData,4));
%     flySDFT=squeeze(std(phenotypeData{thisPhenotype}.normFlyExtractedData,[],4));
%     flySemFT=flySDFT/sqrt(size(phenotypeData{thisPhenotype}.normFlyExtractedData,4));
    
      flyMeanWaveforms=squeeze(mean(phenotypeData{thisPhenotype}.meanWaveform,4));
    flyMeanFT=squeeze(mean(phenotypeData{thisPhenotype}.flyExtractedData,4));
    flySDFT=squeeze(std(phenotypeData{thisPhenotype}.flyExtractedData,[],4));
    flySemFT=flySDFT/sqrt(size(phenotypeData{thisPhenotype}.flyExtractedData,4))
    
    absData=abs(flyMeanFT);
    %
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
    
    
    %Work out some difference statistics.
    % We do a double comparison: (1-2)adapted - (1-2)unadapted.
    contLevels=params.probeContRange;
    contLevels(1)=0.01;
    rawData=phenotypeData{thisPhenotype}.flyExtractedData;
    % raw data is [freqsToextract  (usually: 1F1 and 2F1) x nAdaptation points (4 : 1
    % before and 3 afterwards) x nProbeContrasts in total (12:  6 contrasts
    % >with< 80% contrast adaptor 6 without) x nFlies (ranging between 3 and
    % 15 at this point but mostly about 10)
    

    
    
    diffStat1=(rawData(:,binToCompare(1),:,:)-rawData(:,binToCompare(2),:,:));  % Subtract all block 2s from all block 1s . This is pre-adaptation period - post-adaptation period
    diffStat2=diffStat1(:,1,7:12,:)-diffStat1(:,1,1:6,:); % Compare these between the 80% and 0% adaptation conditions. We expect the difference to be positive if there's an effect...
    
    % Average over flies
    
    meanDiff=squeeze(mean(diffStat2,4)); %
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
    
    % Also write out meanDiff, sem Diff to excel
    sheetName=phenotypeList{thisPhenotype}.type;
    xlwrite('differenceData.xls', abs([meanDiff;semDiff]),sheetName);

    % Also write out raw data for plotting initial graphs
    
   
    figure(121);
    subplot(4,5,thisPhenotype);
    h=boundedline(repmat(contLevels,2,1)',abs(meanDiff)',semDiff');
    legend({'1F','2F'});
    grid on;
    set(gca,'XScale','Log');
    title('Pre-adapt - post-adapt');
    set(gca,'YLim',[0 12])
    title(phenotypeList{thisPhenotype}.type);
end




