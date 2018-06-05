%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;


nSecs=4;
nJunkSecs=1;
sampleRate=256;





dataDir=uigetdir;
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
            meanData(thisRep,thisCond,:,:)=cell2mat(thisRepData(1,thisCond));
        end
            
    end
     allMeanData(thisSession,:,:,:,:)=meanData;   
    % Get rid of first second
    meanDataCropped=meanData(:,:,(nJunkSecs*256+1):end,:,:);
    
    % Reshape into 1/2 sec bins... (128 samples) .. HERE. If we don't
    % reshape (i.e. keep the 3s * 256 points/ sec data) we can compute more
    % (and more accurate) side bins.
    md=reshape(meanDataCropped,[nReps,nConds,128*6,4]); % nReps x nConds x timePointsPerBin x nBins x nChannels
    
    fMD=fft(md,[],3);
    mfMD=(squeeze(mean(fMD))); % Coherent average across reps
    % Also average across bins
    %mmfMD=squeeze(mean(mfMD,3)); % Coherent average across bins
    

    
    % Compute averages over reps
    %grandMeanData(thisSession,:,:,:)=squeeze(mean(abs(ftData))); % Phase incoherent averaging
    grandMeanBins(thisSession,:,:,:)=mfMD; % NSubs x nConds x nTimePoints x nChannels
    
   
    
end
%%
fToAnalyze=6*2; % Frequency of the flicker
nSecs=3; % How many seconds of data do we have per cond?

[u,v,i]=unique(type); % This tells us which patient types we had.
normCont=find(i==1);
PDAll=find(i~=1);
offMedsGenetic=[find(i==4);find(i==6)];

controlGroup=grandMeanBins(normCont,:,:,:);
offGroups=grandMeanBins(offMedsGenetic,:,:,:);


channelsToAverage=[1 2];
% Average across channels
mFTPD_g1=squeeze(mean(controlGroup(:,:,:,channelsToAverage),4));
mFTPD_g2=squeeze(mean(offGroups(:,:,:,channelsToAverage),4));


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

cyclesPerTSeries=fToAnalyze*nSecs;

% Also look at coherence
noiseFreqPerBinHz=setdiff([12:120],[cyclesPerTSeries, cyclesPerTSeries*2,cyclesPerTSeries*3]);

%%
%noiseFreqPerBin=[7 9]
% Compute coherence on a per subject basis
cohBinNoiseG1=squeeze(sqrt(sum(abs(mFTPD_g1(:,:,(noiseFreqPerBinHz+1),:).^2),3)));
cohBinNoiseG2=squeeze(sqrt(sum(abs(mFTPD_g2(:,:,(noiseFreqPerBinHz+1),:).^2),3)));



cohSignalG1=squeeze(mFTPD_g1(:,:,(cyclesPerTSeries+1)))./cohBinNoiseG1;
cohSignalG2=squeeze(mFTPD_g2(:,:,(cyclesPerTSeries+1)))./cohBinNoiseG2;

figure(2);
hold off
meanSigG1=(squeeze(mean(cohSignalG1)));
meanSigG2=(squeeze(mean(cohSignalG2)));


meanSig2G1A=abs(meanSigG1);
meanSig2G2A=abs(meanSigG2);

stSigG1=squeeze(std(cohSignalG1)/sqrt(nSessions));
stSigG2=squeeze(std(cohSignalG2)/sqrt(nSessions));

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
barweb([meanSig2G1A(9);meanSig2G2A(9)],[stSigG1(9);stSigG2(9)],.8);
ylabel('Max unmasked amp');
title('Max unmasked amps');
