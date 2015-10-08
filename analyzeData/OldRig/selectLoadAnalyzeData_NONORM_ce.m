
% This version copes with randomized contrast sequences produced by newer
% versions of the display code.
% It expects the indices of the random sequence to be in
% exptParams{x}.randSeq
% This is a complete rewrite - it includes SNR checking on import (using
% Fieldtrip?), parameter extraction and better plotting.
% This version adds incoherent averaging to look at evoked power.

%%
addmetothepath;
%% Generate a list of all the directories to examine in the destination dir.
clear all; close all; % Housekeeping
MAX_FREQ=100; % Maximum frequency to retain during F-domain analysis.
DOFILENORM=0;

%% needs to be 0
DOFLYNORM=4; % These normalization options allow you to perform normalization on a per-file or per-fly basis. 0 = no normalization 1= full (complex) 2=magnitude only
comment='noNorm';

baseDir=uigetdir(pwd);
[a,b1]=fileparts(baseDir);
b = [baseDir,filesep, b1];
bookName=[b,'_',datestr(now,30),'_',comment,'.pdf']
F2Name=[b,'_',datestr(now,30),'_F2_',comment,'.csv']
aFileName=[b,'_',datestr(now,30),'_AnalysisData_',comment,'.mat']
allDataName=[b,'_',datestr(now,30),'_AllData_',comment,'.mat']

phenotypeList=fly_getDataDirectoriesOrig(baseDir); % This function generates the locations of all the directories..
% Each fly sits in a separate subdirectory. We >want< top do a multivariate repeatedmeasures ANOVA. But we can't in MATLAB. We can in R...
% With the possibility of performing a MVRMA at some
% point, we will load in data and store all data. But
% our summary stats (for now) will be means taken within
% flies.
% % Within each dir, we expect to find Fly1, Fly2 etc... And within these
% subdirs, we will find .mat files like kcc_Ch0_1_20120719T171624.mat
% [genotype]_[LEDchannel]_[sweepRepetition]_YYMMDDTHHMMSS.mat

%ACCEPT_ALL=1; % If this is 1 then we accept all data sets. If it's zero, we ask each time we load something
%DO_QC=1; % If this is set, we do quality control on all datasets. Possibly through the magical medium of Fieldtrip.
% To begin with, see ss_noiseCheck.m

% Freqs to extract are coded as an nx2 matrix containing the weights of the
% F1 and F2 frequencies. So the first two rows might be 1 0;0 1 to get the
% 1F1 and 1F2 on their own.


extractionParams.freqsToExtract=[1 0;0 1;2 0;0 2;1 1;2 2];
extractionParams.freqLabels={'F1','F2','2F1','2F2','F1+F2','2F2+2F1'};
extractionParams.incoherentAvMaxFreq=MAX_FREQ;
extractionParams.rejectParams.sd=2;
extractionParams.rejectParams.maxFreq=MAX_FREQ;
extractionParams.DOFILENORM=0;
extractionParams.SNRFLAG=1;
extractionParams.waveformSampleRate=1000; % Hz. Resample the average waveform to this rate irrespective of the initial rate.

%% Here we load in all the different data files.
[phenotypeData,params]=ss_loadFlyData(phenotypeList,extractionParams);



%%
thisStatIndex=1;
for thisPhenotype=1:length(phenotypeList)
    
    
    % Go into the directory containing the next phenotype and find out how
    % many 'Fly...' subdirectories it contains.
    if isfield(phenotypeList{thisPhenotype}, 'flyDir')
        nFlies=length(phenotypeList{thisPhenotype}.flyDir);
        
        
        tic;
        allFlyResponses=[];
        allNormFlyResponses=[];
        
        for thisFlyIndex=1:nFlies
            % Build up lists of complex response amps
            % Compute the distortion in the output, input.
            
            if isfield( phenotypeData{thisPhenotype}.fly{thisFlyIndex}, 'allfCondDat' ) % Check to see if we can proceed with this dataset...
                thisFlyResp=phenotypeData{thisPhenotype}.fly{thisFlyIndex}.allfCondDat;
                allFlyResponses(thisFlyIndex,:,:,:)=thisFlyResp(:,:,:); %  nFlies * nFreqs x nContrasts x nMaskConds
                nTrials=size(phenotypeData{1}.fly{1}.allfCondDat,2);
                
                switch DOFLYNORM
                    case 1 % Complex normalization - this is a slightly oddthing to do...
                        normPoints=[(nTrials-2):(nTrials)];
                        normFlyVals{thisPhenotype}.value(thisFlyIndex)=nanmean((squeeze(allFlyResponses(thisFlyIndex,1,normPoints,1))));
                        allNormFlyResponses(thisFlyIndex,:,:,:)=allFlyResponses(thisFlyIndex,:,:,:)./  normFlyVals{thisPhenotype}.value(thisFlyIndex);
                    case 2 % Magnitude only
                        normPoints=[(nTrials-2):(nTrials)];
                        normFlyVals{thisPhenotype}.value(thisFlyIndex)=abs(nanmean((abs(squeeze(allFlyResponses(thisFlyIndex,1,normPoints,1))))));
                        allNormFlyResponses(thisFlyIndex,:,:,:)=allFlyResponses(thisFlyIndex,:,:,:)./ normFlyVals{thisPhenotype}.value(thisFlyIndex);
                        
                        %
                    case 3 % Correct for mag and temporal lag. Compute this from the phase as in cond 1 - but then apply to all subsequrent freqs
                        % Do this because we cannot guarantee the polarity  of all
                        % our data - - this flips depending on which electrode went
                        % in the mouth!
                        
                        normPoints=[(nTrials-2):(nTrials)];
                        normFlyVals{thisPhenotype}.value(thisFlyIndex)=nanmean((squeeze(allFlyResponses(thisFlyIndex,1,normPoints,1))));
                        % Phase shifts are different for each freq
                        % For higher freqs they are bigger for a given temporal lag
                        normPhaseShift=angle(normFlyVals{thisPhenotype}.value(thisFlyIndex));
                        normMagShift=abs(normFlyVals{thisPhenotype}.value(thisFlyIndex));
                        frequencyRatios=params.extractedFreqs/params.extractedFreqs(1);
                        freqShifts=frequencyRatios*normPhaseShift;
                        
                        complexNorm=normMagShift*exp(sqrt(-1)*freqShifts);
                        
                        %Make complex norm bigger using repmat
                        [nFreqs,nConts,nExpts]=size(squeeze(allFlyResponses(thisFlyIndex,:,:,:)))
                        
                        
                        normMatrix=repmat(complexNorm(:),[1,nConts,nExpts]);
                        
                        
                        
                        allNormFlyResponses(thisFlyIndex,:,:,:)=squeeze(allFlyResponses(thisFlyIndex,:,:,:))./ normMatrix;
                        
                        
                        %TDDO!!!
                        
                    case 4 % Correct for temporal lag only. This is probably the best option - we have to do it because the polarity of responses is not well-defined. Some measurements have -ve going responses...
                        % Correct for mag and temporal lag. Compute this from the phase as in cond 1 - but then apply to all subsequrent freqs
                        % Do this because we cannot guarantee the polarity  of all
                        % our data - - this flips depending on which electrode went
                        % in the mouth!
                        
                        normPoints=[(nTrials-2):(nTrials)];
                        normFlyVals{thisPhenotype}.value(thisFlyIndex)=nanmean((squeeze(allFlyResponses(thisFlyIndex,1,normPoints,1))));
                        % Phase shifts are different for each freq
                        % For higher freqs they are bigger for a given temporal lag
                        normPhaseShift=angle(normFlyVals{thisPhenotype}.value(thisFlyIndex));
                        frequencyRatios=params.extractedFreqs/params.extractedFreqs(1);
                        freqShifts=frequencyRatios*normPhaseShift;
                        
                        complexNorm=1*exp(sqrt(-1)*freqShifts);
                        
                        %Make complex norm bigger using repmat
                        [nFreqs,nConts,nExpts]=size(squeeze(allFlyResponses(thisFlyIndex,:,:,:)))
                        
                        
                        normMatrix=repmat(complexNorm(:),[1,nConts,nExpts]);
                        
                        
                        
                        allNormFlyResponses(thisFlyIndex,:,:,:)=squeeze(allFlyResponses(thisFlyIndex,:,:,:))./ normMatrix;
                        
                        
                        %TDDO!!!
                    case 5 % Correct for temporal lag only. This is probably the best option - we have to do it because the polarity of responses is not well-defined. Some measurements have -ve going responses...
                        % Correct for mag and temporal lag. Compute this from the phase as in cond 1 - but then apply to all subsequrent freqs
                        % Do this because we cannot guarantee the polarity  of all
                        % our data - - this flips depending on which electrode went
                        % in the mouth!
                        
                        normPoints=[(nTrials-5):(nTrials)];
                        normFlyVals{thisPhenotype}.value(thisFlyIndex,:)=nanmean((squeeze(allFlyResponses(thisFlyIndex,:,normPoints,1))));
                        % Phase shifts are different for each freq
                        % For higher freqs they are bigger for a given temporal lag
                        normPhaseShift=angle(normFlyVals{thisPhenotype}.value(thisFlyIndex,:));
                        
                        
                        complexNorm=1*exp(sqrt(-1).*normPhaseShift);
                        
                        %Make complex norm bigger using repmat
                        [nFreqs,nConts,nExpts]=size(squeeze(allFlyResponses(thisFlyIndex,:,:,:)))
                        
                        
                        normMatrix=repmat(complexNorm(:),[1,nConts,nExpts]);
                        
                        
                        
                        allNormFlyResponses(thisFlyIndex,:,:,:)=squeeze(allFlyResponses(thisFlyIndex,:,:,:))./ normMatrix;
                        
                        
                        %TDDO!!!
                    otherwise
                        
                        allNormFlyResponses(thisFlyIndex,:,:,:)=allFlyResponses(thisFlyIndex,:,:,:);
                end % End of check on NORMALIZATION flag
                
                meanF2Masked(thisStatIndex)=squeeze(nanmean(squeeze((allNormFlyResponses(thisFlyIndex,6,6:8,2)))));
                summaryStatisticName='Mean 2F1+2F2 high cont';
                
                categoryType(thisStatIndex)=thisPhenotype; % There is one entry here per fly in the entire dataset. It tells us what the phenotype of that fly is. Useful for ANOVA etc.
                thisStatIndex=thisStatIndex+1;
            end % End check on existence of 'allfCondDat' field
            
            
        end % Next fly
          analysisStruct.allFlyDataCoh{thisPhenotype}=allFlyResponses; % We make this analysis struct with the same data format for the old and new rigs so that we can analyze all our data in one place...         
          analysisStruct.allNormFlyDataCoh{thisPhenotype}=allNormFlyResponses;
          
          
        mfr=squeeze(nanmean(allFlyResponses));
        nfr=squeeze(nanmean(allNormFlyResponses));
        nmagfr=squeeze(nanmean(abs(allNormFlyResponses)));
        
        meanFlyResp{thisPhenotype}=mfr;
        stdFlyResp{thisPhenotype}=squeeze(nanstd(allFlyResponses));
        semFlyResp{thisPhenotype}=squeeze(stdFlyResp{thisPhenotype}/sqrt(thisFlyIndex));
        
        allResp{thisPhenotype}=allFlyResponses;
        allnResp{thisPhenotype}=allNormFlyResponses;
        meanNormFlyResp{thisPhenotype}=nfr;
        meanAbsNormFlyResp{thisPhenotype}=nmagfr;
        stdNormFlyResp{thisPhenotype}=squeeze(nanstd(abs(allNormFlyResponses)));
        semNormFlyResp{thisPhenotype}=squeeze(stdNormFlyResp{thisPhenotype}/sqrt(thisFlyIndex));
    end % End of isfield if statement
    
    
    
end % Next phenotype


% Fill out the rest of the analysis struct. This contains all the stuff we need to save for
% further analysis
analysisStruct.contRange=linspace(min(params.contRange(:,1)),max(params.contRange(:,1)),length(params.contRange(:,1)));

for thisPhenotype=1:length(phenotypeList)
     analysisStruct.params{thisPhenotype}=params;
     analysisStruct.phenotypeName{thisPhenotype}=phenotypeList{thisPhenotype}.type;
     analysisStruct.nFlies{thisPhenotype}=phenotypeList{thisPhenotype}.nFlies;
     analysisStruct.avWaveform{thisPhenotype}=phenotypeData{thisPhenotype}.avWaveform;
     analysisStruct.meanSpectrum{thisPhenotype}=phenotypeData{thisPhenotype}.meanSpectrum;
     analysisStruct.semSpectrum{thisPhenotype}=phenotypeData{thisPhenotype}.semSpectrum;
     analysisStruct.meanCompSpectrum{thisPhenotype}=phenotypeData{thisPhenotype}.meanCompSpectrum;
end

%% At this point we have extracted the data - the rest of this crufty script is some quick and dirty plotting. It would be better to pass off to a separate analysis function at this point...
save(aFileName,'analysisStruct');

% *********** YOU SHOULD STOP HERE AND WRITE YOUR OWN PLOTTING ROUTINES
% USING 'analysisStruct' - see the script 'generalDataAnalysis' for how to
% do this...

%% *************************************************************************
% Compute some statistics across all the datasets. For now, this is just a
% filler - we will compute multivariate anovas on the complex average of
% the masked 2F1 responses



% Loop over all phenotypes and plot polar and cart data
for thisPhenotype=1:length(phenotypeList)
    
    
    % Go into the directory containing the next phenotype and find out how
    % many 'Fly...' subdirectories it contains.
    
    % nFlies=length(phenotypeList{thisPhenotype}.flyDir);
    % Generate
    
    
    tic;
    
    
    % *****
    plotParams.labelList=extractionParams.freqLabels;
    if (DOFLYNORM==1 || DOFLYNORM==2 || DOFLYNORM==3)
        plotParams.maxYLim=[1 1 0.4 0.2 0.25 0.02]; % Zero for adaptive scaling
    else
        plotParams.maxYLim=[200 300 50 30 50 10]/10000;
    end
    
    
    plotParams.polarLims= plotParams.maxYLim;
    plotParams.subplotDims=[3 4];
    plotParams.subPlotIndices=[1:2:12];
    plotParams.DO_ERRORCIRCS=1;
    plotParams.ptypeName=phenotypeList{thisPhenotype}.type;
    plotParams.contRange=linspace(min(params.contRange(:,1)),max(params.contRange(:,1)),length(params.contRange(:,1)));
    % plotParams.contRange(1)=0.01;
    plotParams.XAxisRangeCart=[0 1];
    plotParams.lineWidthPolar=1.5;
    plotParams.lineWidthCart=2;
    plotParams.errorEnvelope=1;
    
    plotParams.figName = strrep (plotParams.ptypeName,'all', '');
    plotParams.figName = strrep (plotParams.figName,'_', ' ');
    ptName{thisPhenotype}=plotParams.figName ;
    % *******8***
    
    
    
    
    % Do some plotting
    figure('Name',plotParams.ptypeName);  %%%%%%%%%thisPhenotype);
    set(gcf,'Renderer','painters');
    hc= fly_plotCartData(meanNormFlyResp{thisPhenotype},semNormFlyResp{thisPhenotype},plotParams);
    plotParams.subPlotIndices=[2:2:12]; % Odd- numbered subplots are phase
    hp= fly_plotPolarData(meanNormFlyResp{thisPhenotype},semNormFlyResp{thisPhenotype},plotParams);
    %maxfig(gcf,1);
    
    % save this as an EPS file.
    fname=[b, plotParams.ptypeName,'_NoERR_data.eps'];
    
    print('-depsc','-r300', fname);
    % export_fig(bookName,'-pdf','-transparent','-append','-opengl');
    
    no1F=meanNormFlyResp{thisPhenotype};
    %no1F(1:2,:,:)=0;
    
    % resynthWaveforms(thisPhenotype,:,:,:)=ss_synthWaveforms(no1F,freqsToExtract); % Resynthesize synthetic waveforms using just the extracted parameters.
    
    
    
end
%%
% TODO: ANOVA
% First generate a set of lables : phenotype name + n
for thisPType=1:length(phenotypeList)
    
end

fout = fopen (F2Name, 'w');
for thisPhenotype=1:length(meanF2Masked)
    fprintf(fout, '%d, %d, %s, %g \r\n', thisPhenotype, categoryType(thisPhenotype),  ptName{categoryType(thisPhenotype)}, abs(meanF2Masked(thisPhenotype)))
end
fclose (fout);


%% Check sorting. Check for singleton flies / reps
g=find(~isnan(meanF2Masked))
gd1=meanF2Masked(g);
gc1=categoryType(g);
%[d,p,stats]=manova1([real(gd1(:)), imag(gd1(:))],gc1)
[d2,p2,stats2]=manova1([abs(gd1(:)),unwrap(angle(gd1(:)))],gc1)
%%%figure(99);

[Myp, Mytable, Mystats] = anova1(abs(gd1(:)),gc1)
set(gca,'XTickLabel',(ptName));

figure;
c = multcompare(Mystats, 0.05)
title(summaryStatisticName);
%%% the Ynames appear to be in reverse order
set(gca,'YTickLabel',fliplr(ptName)); 

%% maxfig(gcf,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%export_fig(bookName,'-pdf','-transparent','-append');
save(allDataName);

%{
%% Look at some specific interactions - this just plots and compares 3 genotypes
gentypeCat=((gc1==1) | gc1==2 | gc1==3 )
[d2,p2,stats2]=manova1([abs(gd1(gentypeCat)'),unwrap(angle(gd1(gentypeCat)'))],gc1(gentypeCat)')

anova1(abs(gd1(gentypeCat)'),gc1(gentypeCat)')
title(summaryStatisticName);
set(gca,'XTickLabel',ptName);
    maxfig(gcf,1);

  export_fig(bookName,'-pdf','-transparent','-append');
save('allData');
%}

%% Look at normalization values
totalList=[];
catType=[];
for thisPhenotype=1:length(phenotypeList)
    totalList=[totalList;normFlyVals{thisPhenotype}.value(:)];
    catType=[catType;thisPhenotype*ones(length(normFlyVals{thisPhenotype}.value(:)),1)];
    
end
[dn,pn,sn]=manova1([real(totalList),imag(totalList)],catType);
% h99=figure(99);
% %%boxplot([abs(totalList)],catType, 'XTickLabel',ptName);
% set(gca,'XTickLabel',ptName);

% draws the graph with notches
[MyPh, MyPhtable, MyPhstats] = anova1(abs(totalList),catType)
set(gca,'XTickLabel',ptName);

figure;
c = multcompare(MyPhstats, 0.05) 
title('Normalization values');
set(gca,'YTickLabel',fliplr(ptName));
%%%%maxfig(gcf,1);

%%%export_fig(bookName,'-pdf','-transparent','-append');





%% __-- Plot all the spectra from the phenotypes
% figure(30);
%     hold off;
%     subplot(1,1,1);
%     grid on
%
%
% for thisPhenotype=1:length(phenotypeList)
%
%     mSpect=squeeze(phenotypeData{thisPhenotype}.meanSpectrum(:,11,1));
%
%     semSpect=squeeze(phenotypeData{thisPhenotype}.semSpectrum(:,11,1));
%     mSpect(50)=0;
%     semSpect(50)=0;
%    % [handleL(thisPhenotype),handleP(thisPhenotype)]=boundedline(1:199,mSpect,semSpect); % The zero term is already out.
%   handleL(thisPhenotype)=errorbar(mSpect,semSpect);
%    %set(gca,'XLim',[1 nFreqs]);
%     % set(gca,'YScale','log');
%     hold on;
%
%
% end
% legend(ptName);
% colMaps=hsv(length(phenotypeList));
%
% for thisPhenotype=1:length(phenotypeList)
%        set(handleL(thisPhenotype),'Color',colMaps(thisPhenotype,:));
%     set(handleL(thisPhenotype),'LineWidth',2);
%    % set(handleP(thisPhenotype),'FaceColor',colMaps(thisPhenotype,:));
%   %  set(handleP(thisPhenotype),'FaceAlpha',0.5);
% end

%     subplot(2,1,2);
% hold off;
% plot(log(mean(flyMeanSpectrum{2}.data(2:end,:),2))-log(mean(flyMeanSpectrum{4}.data(2:end,:),2)),'g');
% hold on;
% plot(log(mean(flyMeanSpectrum{1}.data(2:end,:),2))-log(mean(flyMeanSpectrum{3}.data(2:end,:),2)),'r');
% hold on;
% grid on
% legend(ptName);

%%
%%Here, we want to compute the binned amplitudes across the endogenous
% frequency bands - ignoring the ones containing actual signal.
% To do that, we first compute the f's containing signal - then work
% out which ones are noise

signalBinMultiples=[1 0;0 1;2 0; 0 2;1 1; 1 -1; 2 -2; 2 2];
signalFs=abs(signalBinMultiples(:,1)*params.F(1)+signalBinMultiples(:,2)*params.F(2));
noiseFs=setdiff(1:99,signalFs);
binBoundaries=[1,10;11,20;21,30;31,40]
for thisPhenotype=1:length(phenotypeList)
    for thisBin=1:size(binBoundaries,1)
        validFs=intersect((binBoundaries(thisBin,1):binBoundaries(thisBin,2)),noiseFs);
        
        totalPower=squeeze(sqrt(sum(phenotypeData{thisPhenotype}.meanSpectrum(noiseFs,:).^2)));
        dataToAverage=(squeeze(phenotypeData{thisPhenotype}.meanSpectrum(validFs,:,:)));
        semToAverage=(squeeze(phenotypeData{thisPhenotype}.semSpectrum(validFs,:,:))).^2;
        
        thisBinRMS(thisPhenotype,thisBin)=sqrt(nanmean(dataToAverage(:).^2))./sum(totalPower'); % This is the average across all mask and probe conrast conditions.
        thisBinSEM(thisPhenotype,thisBin)=sqrt(nanmean(semToAverage(:)))./sum(totalPower');
        binLabel{thisBin}=sprintf('%d to %d',binBoundaries(thisBin,1),binBoundaries(thisBin,2));
        
        
    end
    
    
end
figure(50);
barwitherr(thisBinSEM',thisBinRMS');
title('Normed endogenous RMS activity in different frequency bands')
set(gca,'XTickLabel',binLabel);
xlabel('Bin ranges (Hz)');
ylabel('Average RMS amplitude (AU)');

legend(ptName)


%%


%  %%
%  r1=phenotypeData{1}.avWaveform;
%   r2=phenotypeData{2}.avWaveform;
%
%  pdat=squeeze(r1(:,:,1));
%  pdat=pdat-repmat(mean(pdat),size(pdat,1),1);
%
%
%  figure(120);
% surf(pdat);
% shading interp
% %}
%
% % Plot the mean phase of the high contrast conditions
%
% % allResp contains these complex amplitudes - it is nFlies x nFreqComp *
% % nConts x nExpts
% totalList=[];
% catType=[];
% for thisPhenotype=1:length(phenotypeList)
%     tempData=allResp{thisPhenotype};
%     tempData=squeeze(nanmean(tempData(:,3,((nConts-1):(nConts-1)),1),3));
%     phenoMean(thisPhenotype)=squeeze(nanmean(tempData));
%     phenoSem(thisPhenotype)=squeeze(nanstd(tempData)/sqrt(size(tempData,1)));
%
%      totalList=[totalList;tempData];
%     catType=[catType;thisPhenotype*ones(length(tempData),1)];
% end
% [d,p,stats]=manova1([real(totalList(:)), imag(totalList(:))],catType)
% [d2,p2,stats2]=manova1([abs(totalList(:)), (angle(totalList(:)))],catType)
%
% % Circular statistic test of phase
% circ_cmtest(angle(totalList(:)),catType)
%
%
%
%
%
% figure(250);
% hold off;
% plotParams.DO_ERRORCIRCS=1;
%      % Plot a dummy function to set the scale
%         theta  = linspace(0,2*pi,100);
%         r      = sin(2*theta) .* cos(2*theta);
%         r_max  = 125; % was 25 also been 3
%         h_fake = polar(theta,r_max*ones(size(theta)));
%         set(h_fake,'Color',[1 1 1]);
%
%         hold on;
%         g=compass(real(phenoMean),imag(phenoMean),'k');
%         set(gca,'FontSize',8);
%
%         comap=hsv(length(g));
%
%         for th=1:length(g)
%             %set(g(th),'Color',[1 0.6 0.6]-0.05*th);
%             set(g(th),'Color',comap(th,:));
%             set(g(th),'LineWidth',plotParams.lineWidthPolar);
%             a = get(g(th), 'xdata');  % Get rid of arrows. Thanks StackOverflow!
%             b = get(g(th), 'ydata');
%             set(g(th), 'xdata', a(1:2), 'ydata', b(1:2))
%
%             if (plotParams.DO_ERRORCIRCS)
%
%             x=get(g(th),'XData');
%             y=get(g(th),'YData');
%             rad=phenoSem(th);
%
%             xPos=rad*cos(linspace(0,2*pi,30))+x(2);
%             yPos=rad*sin(linspace(0,2*pi,30))+y(2);
%             p(th)=patch(xPos,yPos,'r');
%             set(p(th),'FaceAlpha',.5);
%             set(p(th),'FaceColor',comap(th,:));
%             end
%
%
%         end
% legend(p,ptName);
%        maxfig(gcf,1);
%
%   export_fig(bookName,'-pdf','-transparent','-append','-opengl');
%      % export_fig('polar.eps','-transparent','-opengl');
%
%
%


%{
% Compute a single minumum bin from the two Fs.
% This is the smallest time interval with an integer number of both cycles
% in it.

 % Quiick look at phase scatter - is it normal or bimodal?
 %%
 p2F1Phase1=squeeze(allResp{1}(:,1,11,1));
 
 p2F1Phase2=squeeze(allResp{2}(:,1,11,1));
 
 figure(301);
 subplot(2,1,1);
 
 compass(p2F1Phase1);
 subplot(2,1,2);
 compass(p2F1Phase2);
%}

%% This bit writes data to XL format. You can disable it if you
%%% want...

xlParams=plotParams; % xlParams doesn't need all the fields here but it's quicker just to clone plotParams. We need labels, contRange and the number of mask conditions
xlParams.phenotypeList=phenotypeList;
[s]=writeFlyDataToXL([bookName,'.xls'],meanNormFlyResp,semNormFlyResp, xlParams); % Write out the data into an xl spreadsheet . We think this is really just a step on the way to R or SPSS...
% The format of the written data is going to be 1 sheet per frequency. All
% the phenotypes will be on the same sheet. They will be coded
% 1,2,3,4,..... All the mask conditions will, similarly, be on the same
% sheet. They will be coded 0,1...
% This is the way to set it up if you want to do an ANOVA ...
% Final problem: All our data are complex. To do the correct stats we
% should keep them complex. But this makes plotting a pain. So we will
% write out just the magnitude data (and the SEMs).
