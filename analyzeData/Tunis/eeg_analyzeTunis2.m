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
    
    % Reshape into 1/2 sec bins... (128 samples)
    md=reshape(meanDataCropped,[nReps,nConds,128,6,4]); % nReps x nConds x timePointsPerBin x nBins x nChannels
    
    fMD=fft(md,[],3);
    mfMD=(squeeze(mean(fMD))); % Coherent average across reps
    % Also average across bins
    mmfMD=squeeze(mean(mfMD,3)); % Coherent average across bins
    

    
    % Compute averages over reps
<<<<<<< Updated upstream
    %grandMeanData(thisSession,:,:,:)=squeeze(mean(abs(ftData))); % Phase incoherent averaging
    grandMeanBins(thisSession,:,:,:)=mmfMD; % NSubs x nConds x nTimePoints x nChannels
=======
    grandMeanData(thisSession,:,:,:)=squeeze(mean((ftData))); % Phase incoherent averaging
    grandMeanBins(thisSession,:,:,:)=mmfMD;
>>>>>>> Stashed changes
    
   
    
end
%%
<<<<<<< Updated upstream
fToAnalyze=6;

=======
>>>>>>> Stashed changes
mFT=squeeze(mean((grandMeanBins)));
figure(1);
subplot(3,1,1);
imagesc(squeeze(abs(mFT(:,fToAnalyze+1,:))));
colorbar;

subplot(3,1,2);
bar(abs(squeeze(mFT(7,2:30,:))));


subplot(3,1,3);
bar(abs(squeeze(mean(mFT(:,fToAnalyze+1,:),3))));


% Also look at coherence
 noiseFreqPerBin=[ 5 7 9 11 13 14 15 17 18]

%noiseFreqPerBin=[7 9]
cohBinNoise=sqrt(sum(abs(grandMeanBins(:,:,(noiseFreqPerBin+1),:).^2),3));
cohSignal=(grandMeanBins(:,:,(fToAnalyze+1),:)./cohBinNoise);
figure(2);
meanSig=(squeeze(mean(cohSignal(:,:,:,1:2))));
meanSig2=abs(squeeze(mean(meanSig,2)));

stSig=squeeze(std(cohSignal(:,:,:,1:2))/sqrt(nSessions));
stSig2=squeeze(mean(stSig,2))/sqrt(2);

errorbar(meanSig2,stSig2);
colormap hot




