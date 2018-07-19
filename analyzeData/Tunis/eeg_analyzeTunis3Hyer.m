%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;


nSecs=4;
nJunkSecs=1;
sampleRate=256;




dataDir='/Users/alexwade/GoogleDrive/Personal/Projects/Tunis/TunisNew/Data';

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
    %grandMeanData(thisSession,:,:,:)=squeeze(mean(abs(ftData))); % Phase incoherent averaging
    grandMeanBins(thisSession,:,:,:)=mmfMD; % NSubs x nConds x nTimePoints x nChannels
    
   
    
end
%%
fToAnalyze=6;

[u,v,i]=unique(type); % This tells us which patient types we had.
normCont=find(i==1);
PDAll=find(i~=1);
offMedsGenetic=[find(i==4);find(i==5)];
%;find(i==8)];

controlGroup=grandMeanBins(normCont,:,:,:);
offGroups=grandMeanBins(offMedsGenetic,:,:,:);
close all


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
    [d1(t),p1(t,:)]=fit_hyper_ratioN2([0, contList],meanSig2G1A(1:8)');

[d2(t),p2(t,:)]=fit_hyper_ratioN2([0,contList],meanSig2G2A(1:8)');
disp(',');
end


avp1=median(p1);
avp2=median(p2);
%%
figure(2);

subplot(1,2,1);
hold on;

h1=plot(contList,hyper_ratio(avp1,contList),'b');
h2=plot(contList,hyper_ratio(avp2,contList),'r');

set(h1,'LineWidth',2);
set(h2,'LineWidth',2);
nBoot=1000;
[ci_1,bs_1]=bootci(nBoot,@fit_hyper_ratioTunis,cohSignalG1(:,1:8));
[ci_2,bs_2]=bootci(nBoot,@fit_hyper_ratioTunis,cohSignalG2(:,1:8));

goodFits1=find(bs_1(:,5)<(mean(bs_1(:,5)+2*std(bs_1(:,5)))));
goodFits2=find(bs_2(:,5)<(mean(bs_2(:,5)+2*std(bs_2(:,5)))));

params1=bs_1(goodFits1,:);
params2=bs_2(goodFits2,:);

mean(params1)
mean(params2)
figure(10);
subplot(1,2,1);
hold off;
ht1=histogram(params1(:,2),linspace(0,1,50));
hold on;
ht2=histogram(params2(:,2),linspace(0,1,50));
xlabel('C50');
subplot(1,2,2);
hold off;
ht1=histogram(params1(:,1),linspace(0,1,50));
hold on;
ht2=histogram(params2(:,1),linspace(0,1,50));
xlabel('Rmax');




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
 
