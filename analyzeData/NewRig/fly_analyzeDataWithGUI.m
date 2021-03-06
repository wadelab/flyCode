% Analyze data using a GUI - structured a bit like the function that runs
% the expts. This is a script delibrately : If it stops halfway through,
% you want to be able to see the data...




%% Generate a list of all the directories to examine in the destination dir.
clear all; close all; % Housekeeping
PHOTODIODE_HIDE=1;
MAX_FREQ=100; % Maximum frequency to retain during F-domain analysis.
DOFILENORM=0;
DOFLYNORM=0 ; % These normalization options allow you to perform normalization on a per-file or per-fly basis. 0 = no normalization 1= full (complex) 2=magnitude only
comment='test';
set(0, 'DefaulttextInterpreter', 'none');


[dataParams,cancelledFlag]=fly_analyzeDataGUI


subDirList=fly_getDataDirectories_multi(dataParams.baseDir); % This function generates the locations of all the directories..
[a,b]=fileparts(baseDir)
bookName=[b,'_',datestr(now,30),'_',comment,'.pdf']


% At this point, there should be the option to select which directories we
% want to look at.

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
extractionParams.freqLabels={'F1','F2','2F1','2F2','F2+F1','2F2+2F1'};
extractionParams.incoherentAvMaxFreq=MAX_FREQ;
extractionParams.rejectParams.sd=2;
extractionParams.rejectParams.maxFreq=MAX_FREQ;
extractionParams.DOFILENORM=0;
extractionParams.SNRFLAG=0;
extractionParams.waveformSampleRate=1000; % Hz. Resample the average waveform to this rate irrespective of the initial rate.
extractionParams.dataChannelIndices=[1 2 3];

%% Here we load in all the different data files.
[subDirData,params]=fly_loadSSData(subDirList,extractionParams);


% This now has two channels (corresponding to two flies). In addition, all
% the mask/probe conditions are contained within the single structures of
% meanCompSpectrum, avWaveform etc. So if there were 7 probe conts and 2
% mask conts, this will be 14 elements long. A typical size for
% 'phenotypeData{1}.avWaveform' is therefore 1000x2x14

%% 
thisStatIndex=1;
exptIndex=1;
 allExptResponses=[];
    allNormExptResponses=[];
for thisSubDir=1:length(subDirList) % Loop over all subdirectories
    
    % Go into each subd irectory. Find out how
    % many 'Expt...' subdirectories it contains.
    
    nExpts=length(subDirList{thisSubDir}.exptDir);

    
    for thisExptIndex=1:nExpts % Loop over all expts in a single subDirectory. An expt is defined as a new set of flies : a new 'pressing of the go button'
        % Build up lists of complex response amps, average waveforms etc
        
        thisExptResponse=subDirData{thisSubDir}.expt{thisExptIndex}.allfCondDat;
        % We just concatenate these responses into a big long list and get
        % the hashing algorithm to sort them out later.
        nFliesInResponseStruct=size(thisExptResponse,2);
        for thisFlyInResp=1:nFliesInResponseStruct
            
            allExptResponses(thisStatIndex,:,:)=squeeze(thisExptResponse(:,thisFlyInResp,:));
            % Make a list of hashes 
            allPTHashes(thisStatIndex)=cellstr(params.outType(exptIndex).flyHash(thisFlyInResp));
            allFlyNames{thisStatIndex}=params.outType(exptIndex).flyName(thisFlyInResp)
            
            thisStatIndex=thisStatIndex+1;
        end % End which fly in resp
        exptIndex=exptIndex+1;
    end % Next experiment
    %
    
end % Next sub directory

%% 
% We can now find out how many unique fly types we have:
[uniqueFlyTypes,uniqueIndices,uniqueJ]=unique(allPTHashes);
nUniqueFlies=length(uniqueFlyTypes);

fprintf('\nFound %d unique fly types in this dataset\n',nUniqueFlies);
for thisFlyTypeIndex=1:nUniqueFlies
    fprintf('\n%s\n',char(allFlyNames{uniqueIndices(thisFlyTypeIndex)}));
    ptypeList{thisFlyTypeIndex}=char(allFlyNames{uniqueIndices(thisFlyTypeIndex)});
    
    
end
%%
% Sort data into unique sets and average
for thisFlyTypeIndex=1:nUniqueFlies
    meanFlyDataCoh(thisFlyTypeIndex,:,:)=nanmean(allExptResponses(find(uniqueJ==thisFlyTypeIndex),:,:),1);
    semFlyDataCoh(thisFlyTypeIndex,:,:)=nansem(allExptResponses(find(uniqueJ==thisFlyTypeIndex),:,:),[],1);
    meanFlyDataInc(thisFlyTypeIndex,:,:)=nanmean(abs(allExptResponses(find(uniqueJ==thisFlyTypeIndex),:,:)),1);
    semFlyDataInc(thisFlyTypeIndex,:,:)=nansem(abs(allExptResponses(find(uniqueJ==thisFlyTypeIndex),:,:)),[],1);
    nFliesInThisType(thisFlyTypeIndex)=sum((uniqueJ==thisFlyTypeIndex));
end


%% Loop over all fly types
plotScales=[ .005 .0005 .001]; % Scales


for thisFlyTypeIndex=1:nUniqueFlies
 fprintf('\n%s',ptypeList{thisFlyTypeIndex});
if (strcmp(ptypeList{thisFlyTypeIndex},'Photodiode') && PHOTODIODE_HIDE)
    % Do nothing
else
    
    plotParams.labelList=extractionParams.freqLabels;
    plotParams.maxYLim=[.05 .05 .008 .005 .01 .0008];%.*plotScales(thisFlyTypeIndex);
    
    plotParams.polarLims= plotParams.maxYLim/2;
    plotParams.subplotDims=[2 3];
    plotParams.subPlotIndices=[1:6];
    plotParams.DO_ERRORCIRCS=1;
    plotParams.ptypeName=ptypeList{thisFlyTypeIndex};
    plotParams.contRange=linspace(min(params.contRange(:,1)),max(params.contRange(:,1)),length(params.contRange(:,1))/2);
    plotParams.XAxisRangeCart=[0 1];
    plotParams.lineWidthPolar=1.5;
    plotParams.lineWidthCart=2;
    plotParams.errorEnvelope=1;

    
    % Do some plotting
    figure(thisFlyTypeIndex*2-1);
    set(gcf,'Renderer','OpenGL')
    % The plotting routine assumes that data are nFreqs x nConts x 2
    % (masked, unmasked)
    dataToPlot=squeeze((meanFlyDataCoh(thisFlyTypeIndex,:,:)));
    semToPlot=squeeze(semFlyDataCoh(thisFlyTypeIndex,:,:));
    
    nConts=size(dataToPlot,2);
    nFreqs=size(dataToPlot,1);
    dataToPlot=reshape(dataToPlot,[nFreqs,nConts/2,2]);
    semToPlot=reshape(semToPlot,[nFreqs,nConts/2,2]);
    
    
    hc= fly_plotCartData(abs(dataToPlot),semToPlot,plotParams);
    set(gcf,'Name',ptypeList{thisFlyTypeIndex});


    plotParams.subPlotIndices=[2:2:12]; % Odd- numbered subplots are phase
      % Do some plotting
      if (strcmp(computer,'PCWIN'))
          disp('Cannot plot polar on 32bit windows');
      else
    figure(thisFlyTypeIndex*2);
    set(gcf,'Renderer','OpenGL')
    hp= fly_plotPolarData(dataToPlot,semToPlot,plotParams);
      end
      
    %maxfig(gcf,1);
    %set(gcf,'Renderer','painters')
    % save this as an EPS file.
    %fname=[plotParams.ptypeName,'_NoERR_data.eps'];
    %print('-depsc','-r300', fname);
 
end
end
return
%%
clear dataToPlot
clear semToPlot;

% Different plots here:
% Column 1 is G2019S 1F1, 2F1, 2F2, 2F IM, Column 2 is w- Column 3 is hLRRK2
plotParams.subplotDims=[4 4];
plotParams.subPlotIndices=[1:16];

plotParams.maxYLim=[180 180 180 35 35 35 15 15 15 5 5 5];
plotParams.labelList={'F1','F1','F1','2F1','2F1','2F1','F2','F2','F2','2F1+2F2','2F1+2F2','2F1+2F2'};
plotParams.ptypeName='';
plotParams.lineWidthPolar=3;
ptIndex=1;
 
% ?? dies in this bit
for thisPhenotype=[4 1 2 3];
    freqIndex=0;
    for thisFreq=[1 3 4 6]
        dataToPlot(freqIndex*3+ptIndex,:,:)=squeeze(meanNormFlyResp{thisPhenotype}(thisFreq,:,:));
        semToPlot(freqIndex*3+ptIndex,:,:)=squeeze(semNormFlyResp{thisPhenotype}(thisFreq,:,:));
        freqIndex=freqIndex+1
    end
    
    
    ptIndex=ptIndex+1
end




figure(601);
hc= fly_plotCartData(dataToPlot,semToPlot,plotParams);
set(gcf,'Renderer','opengl');


%%
% TODO: ANOVA
% First generate a set of lables : phenotype name + n
for thisPType=1:length(phenotypeList)
    ptName{thisPType}=phenotypeList{thisPType}.type;
end



%export_fig(bookName,'-pdf','-transparent','-append');
save('allData');



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

% Do some plotting - This is for Figure 3 comparing THw-, hLRRK2 and
% G2019S
if (DOFLYNORM==1 || DOFLYNORM==2)
    plotParams.maxYLim=[1 0.3 0.02 0.05]; % Zero for adaptive scaling
else
    plotParams.maxYLim=[180 35 5 10];
end
plotParams.subPlotIndices=1:9;
plotParams.subplotDims=[2 2];
plotParams.ptypeName='';
plotParams.labelList={'1F1', '2F1','2F1+2F2','2F2'};

figure(thisPhenotype+200);
cartDataExtract=[1 3 6 4];
cartData1=meanNormFlyResp{1};

cartDataAll=cartData1(cartDataExtract,:,:);

semData1=semNormFlyResp{2};
semDataAll=semData1(cartDataExtract,:,:);




hc= fly_plotCartData(cartDataAll,semDataAll,plotParams);
set(gcf,'Renderer','opengl');


%% Do some more plotting : Phase data from THw-, hLRRK2, G2019S: 2F1, 2F2, 2F2+2F1
% HERE - just plot data from 7th contrast level on each phenotype - this
% catches the peaks of the IM and relatively large responses in the 2F1,
% 2F2
plotParams.subPlotIndices=1;
plotParams.subplotDims=[1 1];
plotParams.ptypeName='';
plotParams.labelList={'1F1'};
plotParams.maxYLim=[10];
plotParams.polarLims= plotParams.maxYLim/2;
clear phaseDataToPlot;
clear phaseSemToPlot;
plotParams.lineWidthPolar=3;
peakCont=7;
ptIndex=1;
for thisPhenotype=[4 2 1 2];
    freqIndex=1;
    for thisFreq=[ 3]
        phaseDataToPlot(freqIndex,thisPhenotype,1)=squeeze(meanNormFlyResp{thisPhenotype}(thisFreq,peakCont,1));
        phaseSemToPlot(freqIndex,thisPhenotype,1)=squeeze(semNormFlyResp{thisPhenotype}(thisFreq,peakCont,1));
        phaseDataToPlot(freqIndex,thisPhenotype,2)=squeeze(meanNormFlyResp{thisPhenotype}(thisFreq,peakCont,2));
        phaseSemToPlot(freqIndex,thisPhenotype,2)=squeeze(semNormFlyResp{thisPhenotype}(thisFreq,peakCont,2));
        freqIndex=freqIndex+1
    end
    
    
    ptIndex=ptIndex+1
end


figure(602);
hc2= fly_plotPolarData(phaseDataToPlot,phaseSemToPlot,plotParams);
for t=1:length(hc2(:))
    set(hc2,'LineWidth',4);
end

set(gcf,'Renderer','opengl');
%%
return
%plotParams.subPlotIndices=[2:2:12]; % Odd- numbered subplots are phas    %hp= fly_plotPolarData(meanNormFlyResp{thisPhenotype},semNormFlyResp{thisPhenotype},plotParams);
maxfig(gcf,1);
print -depsc -r300 'Figure4JNS.eps'
export_fig('phasePlot','-pdf','-transparent','-append','-painters');


%% For figure 4x1 - also show the phase plots for 2F1, 2F2, 1F1+1F2, 2F1+2F2
% Plot only the masked conditions -  highest contrast responses
% all on same graphs?


% ******************

%% ***************** THIS IS AS SEPARATE
tic
matlabpool('open',4);
options=statset('UseParallel','always');
toc
disp('Assigned matlabpool');


% Bootstrap RMax, c50,for 2F1 data...
thisPhenotype=1;


for thisPhenotype=1:length(phenotypeData)
    % Get the 2F2 data
    allPTData=allResp{thisPhenotype};
    dataToFit2F1=(squeeze(allPTData(:,3,:,:)));
    dataToFit1F1=(squeeze(allPTData(:,1,:,:)));
    contrasts=plotParams.contRange;
    fprintf('\n%d phenotype',thisPhenotype);
    
    
    tic
    [cixxUnmasked1F1{thisPhenotype},xxUnmasked1F1{thisPhenotype}]=bootci(300,{@fit_hyper_ratioNoErrMean,squeeze(dataToFit1F1(:,:,1)),5,0},'Options',options,'alpha',0.05);%,'type','cper');
    [cixxMasked1F1{thisPhenotype},xxMasked1F1{thisPhenotype}]=bootci(300,{@fit_hyper_ratioNoErrMean,squeeze(dataToFit1F1(:,:,2)),5,0},'Options',options,'alpha',0.05);%,'type','cper');
    toc
    
    
    % Get the 2F2 data
    
    fprintf('\n.');
    
    
    tic
    [cixxUnmasked2F1{thisPhenotype},xxUnmasked2F1{thisPhenotype}]=bootci(300,{@fit_hyper_ratioNoErrMean,squeeze(dataToFit2F1(:,:,1)),5,0},'Options',options,'alpha',0.05);%,'type','cper');
    [cixxMasked2F1{thisPhenotype},xxMasked2F1{thisPhenotype}]=bootci(300,{@fit_hyper_ratioNoErrMean,squeeze(dataToFit2F1(:,:,2)),5,0},'Options',options,'alpha',0.05);%,'type','cper');
    toc
    disp('.');
    
end

matlabpool close


%% All plotting.....



for thisPhenotype=1:length(phenotypeData)
    meanUnmaskedPars(thisPhenotype,:)=mean(xxUnmasked2F1{thisPhenotype});
    meanMaskedPars(thisPhenotype,:)=mean(xxMasked2F1{thisPhenotype});
    c50(thisPhenotype,:,1)=xxUnmasked2F1{thisPhenotype}(:,2);
    c50(thisPhenotype,:,2)=xxMasked2F1{thisPhenotype}(:,2);
    Rmax(thisPhenotype,:,1)=xxUnmasked2F1{thisPhenotype}(:,1);
    Rmax(thisPhenotype,:,2)=xxMasked2F1{thisPhenotype}(:,1);
end
for thisPhenotype=1:length(phenotypeData)
    meanUnmaskedPars(thisPhenotype,:)=mean(xxUnmasked1F1{thisPhenotype});
    meanMaskedPars(thisPhenotype,:)=mean(xxMasked1F1{thisPhenotype});
    c501(thisPhenotype,:,1)=xxUnmasked1F1{thisPhenotype}(:,2);
    c501(thisPhenotype,:,2)=xxMasked1F1{thisPhenotype}(:,2);
    Rmax1(thisPhenotype,:,1)=xxUnmasked1F1{thisPhenotype}(:,1);
    Rmax1(thisPhenotype,:,2)=xxMasked1F1{thisPhenotype}(:,1);
end

%%

for ptInterest=2:2
    figure(401);
    title('c50 and Rmax - wt');
    subplot(2,1,1);
    
    h=boxplot(squeeze(c50(ptInterest,:,:)),'plotstyle','compact','boxstyle','outline','notch','on','Colors',[0.5 0.5 0.5;0.9 0.3 0.3],'symbol','k','medianstyle','target','labels',{'Unmasked','Masked'});
    for t=1:length(h(:))
        set(h(t),'LineWidth',3);
    end
    set(gca,'FontSize',14)
    
    set(gcf,'Position',[670 187 213 908]);
    ylabel('c50 2F1');
    set(gca,'YLim',[0 1]);
    
    disp('----*****===');
    subplot(2,1,2);
    
    hb=boxplot(squeeze(Rmax(ptInterest,:,:)),'plotstyle','compact','boxstyle','outline','notch','on','Colors',[0.5 0.5 0.5;0.9 0.3 0.3],'symbol','k','medianstyle','target','labels',{'Unmasked','Masked'});
    disp('...******....');
    for t=1:length(hb(:))
        set(hb(t),'LineWidth',3);
    end
    set(gca,'FontSize',14)
    
    ylabel('Rmax');
    set(gca,'YLim',[0 60]);
    
    disp('----*****===');
    ylabel('Rmax 2F1');
    
    % Save this figure as an .ai
    fName=[ptName{ptInterest},'_boxplot2F1.ai']
    %print -depsc -r300 'Figure4JNS.eps'
    export_fig(fName,'-pdf','-transparent','-painters')
    
    % ************* DISTRIBUTIONS ********
    distLocC2=linspace(0,1,100);
    distLocR2=linspace(0,60,100);
    distLocC1=linspace(0,1,100);
    distLocR1=linspace(0,250,100);
    % These  are the 2F1 data fits...
    figure(402);
    hold off;
    subplot(2,1,1);
    hold off;
    
    [n,x]=hist(squeeze(c50(ptInterest,:,1)),distLocC2);
    bbh1=bar(x,n/sum(n));
    title('2F1');
    xlabel('Bootstrapped value');
    ylabel('Fraction total samples');
    
    
    set(gca,'XLim',[0 1]);
    
    hold on;
    [n,x]=hist(squeeze(c50(ptInterest,:,2)),distLocC2);
    bbh2=bar(x,n/sum(n));
    set(bbh1,'FaceColor',[0.3 0.3 0.3]);
    set(bbh2,'EdgeColor',[0.8 0.8 0.8]);
    xlabel('Bootstrapped value');
    ylabel('Fraction total samples');
    set(bbh2,'FaceColor',[1 0 0]);
    set(bbh2,'EdgeColor',[0.6 0.1 0.1]);
    subplot(2,1,2);
    hold off;
    [n,x]=hist(squeeze(Rmax(ptInterest,:,1)),distLocR2);
    bbh1=bar(x,n/sum(n));
    xlabel('Bootstrapped value');
    ylabel('Fraction total samples');
    set(bbh1,'FaceColor',[0.3 0.3 0.3]);
    set(bbh1,'EdgeColor',[0.8 0.8 0.8]);
    hold on;
    [n,x]=hist(squeeze(Rmax(ptInterest,:,2)),distLocR2);
    bbh2=bar(x,n/sum(n));
    set(bbh2,'FaceColor',[1 0 0]);
    set(bbh2,'EdgeColor',[0.6 0.1 0.1]);
    
    
    % Save this figure as an .ai
    fName=[ptName{ptInterest},'_dist2F1.ai']
    %print -depsc -r300 'Figure4JNS.eps'
    export_fig(fName,'-pdf','-transparent','-painters')
    
    
    
    % ************* MORE DISTRIBUTIONS *************
    figure(403);
    hold off;
    subplot(2,1,1);
    hold off;
    [n,x]=hist(squeeze(c501(ptInterest,:,1)),distLocC1);
    
    bbh1=bar(x,n/sum(n));
    xlabel('Bootstrapped value');
    ylabel('Fraction total samples');
    
    title('1F1');
    set(bbh1,'FaceColor',[0.3 0.3 0.3]);
    set(bbh1,'EdgeColor',[0.3 0.3 0.3]);
    set(gca,'XLim',[0 1]);
    hold on;
    [n,x]=hist(squeeze(c501(ptInterest,:,2)),distLocC1);
    bbh2=bar(x,n/sum(n));
    set(bbh2,'FaceColor',[1 0 0]);
    set(bbh2,'EdgeColor',[0.6 0.1 0.1]);
    subplot(2,1,2);
    hold off;
    [n,x]=hist(squeeze(Rmax1(ptInterest,:,1)),distLocR1);
    bbh1=bar(x,n/sum(n));
    xlabel('Bootstrapped value');
    ylabel('Fraction total samples');
    set(bbh1,'FaceColor',[0.3 0.3 0.3]);
    set(bbh1,'EdgeColor',[0.3 0.3 0.3]);
    hold on;
    [n,x]=hist(squeeze(Rmax1(ptInterest,:,2)),distLocR1);
    bbh2=bar(x,n/sum(n));
    set(bbh2,'FaceColor',[1 0 0]);
    set(bbh2,'EdgeColor',[0.6 0.1 0.1]);
    
    
    % Save this figure as an .ai
    fName=[ptName{ptInterest},'_dist1F1.ai']
    %print -depsc -r300 'Figure4JNS.eps'
    export_fig(fName,'-pdf','-transparent','-painters')
    
    % *****************************
    
    
    figure(501);help cin
    title('c50 and Rmax - wt- 1F1');
    subplot(2,1,1);
    
    h=boxplot(squeeze(c501(ptInterest,:,:)),'plotstyle','compact','boxstyle','outline','notch','on','Colors',[0.5 0.5 0.5;0.9 0.3 0.3],'symbol','k','medianstyle','target','labels',{'Unmasked','Masked'},'extrememode','compress');
    for t=1:length(h(:))
        set(h(t),'LineWidth',3);
    end
    set(gca,'FontSize',14)
    
    set(gcf,'Position',[670 187 213 908]);
    ylabel('c50 1F1');
    set(gca,'YLim',[0 1]);
    subplot(2,1,2);
    
    hb=boxplot(squeeze(Rmax1(ptInterest,:,:)),'plotstyle','compact','boxstyle','outline','notch','on','Colors',[0.5 0.5 0.5;0.9 0.3 0.3],'symbol','k','medianstyle','target','labels',{'Unmasked','Masked'},'extrememode','compress');
    for t=1:length(hb(:))
        set(hb(t),'LineWidth',3);
    end
    set(gca,'FontSize',14)
    
    set(gca,'YLim',[0 1]);
    
    disp('----*****===');
    ylabel('Rmax 1F1');
    
    % Save this figure as an .ai
    fName=[ptName{ptInterest},'_boxplot1F1.ai']
    %print -depsc -r300 'Figure4JNS.eps'
    export_fig(fName,'-pdf','-transparent','-painters')
    
    % **********************
    
    
    for t=1:length(phenotypeList)
        disp('********')
        disp(t);
        
        cixxUnmasked1F1{t}
        cixxMasked1F1{t}
        cixxUnmasked2F1{t}
        cixxMasked2F1{t}
    end
    
    
    
    
    % ************************ Plot the fitted lines on the data
    figure(404);
    subplot(2,1,1);
    hold off;
    
    allPTData=(allResp{ptInterest});
    %  dataToFit2F1=abs(squeeze(allPTData(:,3,:,:)));
    %  dataToFit1F1=abs(squeeze(allPTData(:,1,:,:)));
    
    
    dataToFit1=abs(squeeze(mean((allPTData(:,1,:,:))))); % Take the 1st harmonic frequency - 2F1
    dataToFit2=abs(squeeze(mean((allPTData(:,3,:,:))))); % Take the 1st harmonic frequency - 2F1
    
    plot(0.05,dataToFit1(1),'k.');
    
    hold on
    dots1F1=plot(contrasts(2:end),abs(dataToFit1(2:end,:)),'.');
    set(dots1F1(1),'Color','k');
    set(dots1F1(2),'Color','r');
    set(dots1F1(1),'MarkerSize',20);
    set(dots1F1(2),'MarkerSize',20);
    
    contRange=linspace(0.07,1,100);
    line1=hyper_ratio(median(xxUnmasked1F1{ptInterest}),contRange);
    xlabel('Contrast');
    ylabel('Normalized response - 1F1');
    hold on;
    hl1=plot(contRange,line1,'k');
    set(hl1,'LineWidth',3);
    set(hl1,'Color',[0.5 0.5 0.5]);
    
    line2=hyper_ratio(median(xxMasked1F1{ptInterest}),contRange);
    
    hl2=plot(contRange,line2,'r');
    set(hl2,'LineWidth',3);
    set(hl2,'Color',[0.9 0.5 0.5]);
    set(gca,'XLim',[0 1]);
    set(gca,'YLim',[0 1]);
    plot(0,0,'.');
    
    set(gca,'XScale','Log');
    grid on;
    
    subplot(2,1,2);
    hold off;
    plot(0.05,dataToFit2(1,1),'k.');
    hold on
    dots=plot(contrasts(2:end),abs(dataToFit2(2:end,:)),'.');
    
    set(dots(1),'Color','k');
    set(dots(2),'Color','r');
    set(dots(1),'MarkerSize',20);
    set(dots(2),'MarkerSize',20);
    
    line3=hyper_ratio(median(xxUnmasked2F1{ptInterest}),contRange);
    
    
    hold on;
    hl1=plot(contRange,line3,'k');set(hl1,'LineWidth',3);
    
    
    set(hl1,'Color',[0.5 0.5 0.5]);
    line4=hyper_ratio(median(xxMasked2F1{ptInterest}),contRange);
    hl2=plot(contRange,line4,'r');
    set(hl2,'LineWidth',3);
    set(hl2,'Color',[0.9 0.5 0.5]);
    set(gca,'XLim',[0 1]);
    set(gca,'YLim',[0 40]);
    plot(0,0,'.');
    xlabel('Contrast');
    ylabel('Normalized response - 2F1');
    set(gca,'XScale','Log');
    grid on;
    
    % Save this figure as an .ai
    fName=[ptName{ptInterest},'_fittedLines1F12F1.ai']
    %print -depsc -r300 'Figure4JNS.eps'
    export_fig(fName,'-pdf','-transparent','-painters')
    
    
    
end
