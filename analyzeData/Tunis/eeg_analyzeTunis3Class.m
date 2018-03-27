%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
% New version 0 we want to use a linear classifier to try to classify types
% based on all the harmonics and all the contrasts.

nSecs=5;
nJunkSecs=1;
sampleRate=256;


binSizeSecs=.5;

samplesPerBin=binSizeSecs*sampleRate;
binsInTotal=70;
nChannels=4;
dataDir='/Volumes/GoogleDrive/My Drive/Personal/Projects/Tunis/TunisNew/Data';

%dataDir=uigetdir;
fList=dir(fullfile(dataDir,'EEG_*.mat'))

nSessions=length(fList);
% Generate an empty matrix of NaNs

%%
for thisSession=1:nSessions
    fName=fullfile(dataDir,fList(thisSession).name)
    
    dataSetName=fullfile(fName); % Fullfile generates a legal filename on any platform
    
    thisD=load(dataSetName);
    type{thisSession}=thisD.finalData.patientInfo.group;
    
    dataSet=thisD.finalData.data;
    
    [nReps,nConds]=size(dataSet);

    patientInfo=thisD.finalData.patientInfo
    stim=thisD.d.Stim;
    shuffleOrder=stim.presentOrder; % Randomized on each repetition
    
    
    % It would be really cool to resort the data in one go... Can we do
    % this?
    
    [s,i]=sort(shuffleOrder');
   % i=shuffleOrder';
    clear sortedData
    clear meanData
    
    for thisRep=1:nReps
        thisRepData=dataSet(thisRep,i(:,thisRep));  % This is now a 1xnConds cell array
        
        sortedData{thisRep,:}=thisRepData;
        
        for thisCond=1:nConds
            meanData(:,thisRep,:,thisCond)=(cell2mat(thisRepData(1,thisCond)));
        end
            
    end
    
    
    [d1,nSamples,nChans,d1]=size(meanData);
    %allMeanData(thisSession,:,:,:)=reshape(meanData,  
    % Get rid of first second
    meanDataCropped=meanData((nJunkSecs*samplesPerBin+1):end,:,:,:);%(nJunkSecs*samplesPerBin+1):end,:,:);
    
    % Reshape into 1/2 sec bins... (128 samples)
    md=reshape(meanDataCropped,[samplesPerBin,binsInTotal,nChannels,nConds]); % nReps x nConds x timePointsPerBin x nBins x nChannels
    
    fMD=fft(md,[],1);
    
    
% We don't want all the data - just the nF1 bins
    fToAnalyze=[6 12 18 24];
    goodFreqs=fMD(fToAnalyze+1,:,:,:);
    % Okay - now we also have 4 electrodes for each of those Fs. And each 4
    % F has two components and we also have 9 conditions. These >all< go
    % into the SVM
    [nGF,nBinsInTotal,d1,d2]=size(goodFreqs);
    
    shiftedGood=shiftdim(goodFreqs,1);
    reshapedBins=shiftedGood(1:70,:);
    allSensors(thisSession,:,:)=[real(reshapedBins),imag(reshapedBins)];
    
    
    
end
%%
% Approximately - we have 194 sessions with 70 reps of 212 dimensions. I
% don't think that's ideal - but we can but it down by using averages over
% channels I expect....

%%
[u,v,i]=unique(type); % This tells us which patient types we had.
normCont=find(i==1);
PDAll=find(i~=1);
offMedsGenetic=[find(i==4);find(i==5)];
onMedsGenetic=[find(i==2);find(i==3)];


% Here we now do the fancy bootstrapping
% The situation is a little different to what we are used to
% Before, we classify between conditions run on a single subject - then
% average those classificaiton accuracies across subs
% Here each subject is a different instance of a condition. 
% I >think< what we do in the bootstraps is to take small, random samples
% of bins from each sub and average them to get a new virtual subject.
% I don't really see why we can't do this a lot to generate millions of
% subjects then run a single classify with k-fold validation
% But psycholgists like error bars - so we'll 
nBootStrapRuns=1000;
%condA=normCont;
%condB=offMedsGenetic;

totalSamples=nBinsInTotal;
nBinsToAveragePerIteration=20;
       

for thisBootIndex = 1:nBootStrapRuns % Repeat the sampling over a large number of bootstrapped resamples of different averaged sets
        condA=onMedsGenetic; %Testing
        condB=offMedsGenetic;%PDAll;   
 labels=[ones(length(condA),1)*-1;ones(length(condB),1)];
        Aindices = randperm(nBinsInTotal,nBinsToAveragePerIteration); % Randomly permute the set of sample indices.
        Bindices = randperm(nBinsInTotal,nBinsToAveragePerIteration); % Assumes each subject has been run on the same protocol
       
        AdataCond = squeeze(allSensors(condA,Aindices,:)); % Then pick out a set relevant to the conditions we are looking at right now.
        BdataCond = squeeze(allSensors(condB,Bindices,:));
        
        datameanvectACond=(squeeze(mean(AdataCond,2)));
        datameanvectBCond=(squeeze(mean(BdataCond,2)));
        mean(datameanvectACond(:))
      
            fullData=zscore([datameanvectACond;datameanvectBCond]);
            svmModel=fitcsvm(fullData,labels);
            crossValModel = crossval(svmModel);
       

         % svmModel=fitclinear(fullData,labels,'kfold',5);
         % crossValModel = crossval(svmModel,5);
          lossFun(thisBootIndex)= crossValModel.kfoldLoss;
          disp(thisBootIndex);
%ce = 

        
    end % next boot
    lossFun
    %% ****** THIS BIT FROM PREVIOUS F-domain MMY work



controlGroup=grandMeanBins(normCont,:,:,:);
offGroups=grandMeanBins(offMedsGenetic,:,:,:);
close all


%channelsToAverage=[1 2];
% Average across channels
%mFTPD_g1=squeeze(mean(controlGroup(:,:,:,channelsToAverage),4));
%mFTPD_g2=squeeze(mean(offGroups(:,:,:,channelsToAverage),4));


% figure(1);
% subplot(3,1,1);
% imagesc(squeeze(abs(mFT(:,fToAnalyze+1,:))));
% colorbar;
% 
% subplot(3,1,2);
% bar(abs(squeeze(mFT(7,2:30,:))));
% 
% 
% subplot(3,1,3);
% bar(abs(squeeze(mean(mFT(:,fToAnalyze+1,:),3))));


% Also look at coherence
% noiseFreqPerBin=[  2 3 4 5 7 9 11 13 14 15 17 18 19 20 21 22 23]

noiseFreqPerBin=[3 4 5 7 8 9]
% Compute coherence on a per subject basis
cohBinNoiseG1=squeeze(sqrt(sum(abs(mFTPD_g1(:,:,(noiseFreqPerBin+1),:).^2),3)));
cohBinNoiseG2=squeeze(sqrt(sum(abs(mFTPD_g2(:,:,(noiseFreqPerBin+1),:).^2),3)));


cohSignalG1=(squeeze(mFTPD_g1(:,:,(fToAnalyze+1)))./cohBinNoiseG1);
cohSignalG2=(squeeze(mFTPD_g2(:,:,(fToAnalyze+1)))./cohBinNoiseG2);

figure(2);
hold off;
meanSigG1=(squeeze(mean(cohSignalG1)));
meanSigG2=(squeeze(mean(cohSignalG2)));


meanSig2G1A=abs(meanSigG1);
meanSig2G2A=abs(meanSigG2);

stSigG1=squeeze(std(cohSignalG1)/sqrt(length(cohSignalG1)));
stSigG2=squeeze(std(cohSignalG2)/sqrt(length(cohSignalG2)));

contList=[0.001 .02 .04 .08 .16 .32 .69];
hold off;
subplot(1,2,1);

h1=errorbar(contList,meanSig2G1A(2:8),stSigG1(2:8),'b');
title('Max unmasked amps');

ylabel('Masked responses');
hold on
h2=errorbar(contList,meanSig2G2A(2:8),stSigG2(2:8),'r');
colormap hot
grid on;
set(gca,'XScale','Log');

set(h1,'LineWidth',2);
set(h2,'LineWidth',2);
legend('Control','GenPDOff')
subplot(1,2,2);
bar([meanSig2G1A(9);meanSig2G2A(9)]',[stSigG1(9);stSigG2(9)]');
ylabel('Max unmasked amp');
title('Max unmasked amps');


%% Great, now fit and boot the data.
% First just fit the mean.
nFits=2;

for t=1:nFits
    [p1(t,:)]=fit_powerFunTunis(meanSig2G1A(1:8)');

[p2(t,:)]=fit_powerFunTunis(meanSig2G2A(1:8)');
disp(',');
end


avp1=median(p1);
avp2=median(p2);
%%
figure(2);

subplot(1,2,1);
hold on;

h1=plot(contList,powerFunction(avp1,contList),'b');
h2=plot(contList,powerFunction(avp2,contList),'r');

set(h1,'LineWidth',2);
set(h2,'LineWidth',2);
nBoot=10;
[ci_1,bs_1]=bootci(nBoot,@fit_powerFunTunis,cohSignalG1(:,1:8));
[ci_2,bs_2]=bootci(nBoot,@fit_powerFunTunis,cohSignalG2(:,1:8));

ci_1
ci_2
avp1
avp2
%%
figure(3);
subplot(2,1,1);
hist(bs_2(:,2))
subplot(2,1,2);
hist(bs_1(:,2))
 
