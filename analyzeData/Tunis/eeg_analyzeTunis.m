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

    patientInfo=thisD.finalData.patientInfo;
    stim=thisD.d.Stim;
    shuffleOrder=stim.presentOrder; % Randomized on each repetition
    
    
    % It would be really cool to resort the data in one go... Can we do
    % this?
    
    [s,i]=sort(shuffleOrder');
   % i=shuffleOrder';
    clear sortedData
    clear meanData
    for thisRep=1:nReps
        thisRepData=dataSet(thisRep,i(:,thisRep));
        sortedData{thisRep,:}=thisRepData;
        for thisCond=1:nConds
            meanData(thisRep,thisCond,:,:)=cell2mat(thisRepData(1,thisCond));
        end
        
        %sortedData(thisRep,:);
        
    
    end
    % Get rid of first second
    meanData=meanData(:,:,(nJunkSecs*256+1):end,:,:);
    
    % Reshape into 1/2 sec bins... (128 samples)
    md=reshape(meanData,[nReps,nConds,128,6,4]);
    
    fMD=abs(fft(md,[],3));
    mfMD=squeeze(mean(fMD));
    % Also average across bins
    mmfMD=squeeze(mean(mfMD,3));
    
    
    
    
    % Compute FT 
    ftData=fft(meanData,[],3);
    
    % Compute averages over reps
    grandMeanData(thisSession,:,:,:)=squeeze(mean(abs(ftData))); % Phase incoherent averaging
    grandMeanBins(thisSession,:,:,:)=mmfMD;
    
   
    
end
%%
mFT=squeeze(mean(abs(grandMeanBins)));
figure(1);
imagesc(squeeze(abs(mFT(:,6*3+1,:))));
colorbar;

figure(2);
bar(squeeze(mFT(7,2:100,:)));



