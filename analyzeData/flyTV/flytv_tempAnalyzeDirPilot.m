%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;
fList=dir(fullfile(dataDir,'*.mat'))

nTrials=length(fList);

for thisTrial=1:nTrials
    fName=fullfile(dataDir,fList(thisTrial).name)
    
    
    dataSet=fullfile(fName); % Fullfile generates a legal filename on any platform
    thisD=load(dataSet);
    [nTF,nSF]=size(thisD.dataSet)
    nSecs=9; % number of good 1sec bins
    nPreBin=1; % In secs
    nPostBin=1; % In secs
    sampleFreq=1000; % Samples per sec
 
    % r contains the randomized sequence.
    % Zero this dataset so that we can fill it in.
    outAmplitude1F1(thisTrial,:,:)=zeros(nTF,nSF);
    outAmplitude2F1(thisTrial,:,:)=zeros(nTF,nSF);
    outNoise(thisTrial,:,:)=zeros(nTF,nSF);

    for thisTFIndex=1:nTF
        for thisSFIndex=1:nSF
            allRespData=thisD.dataSet{thisTFIndex,thisSFIndex}; % We can look in r to see which condition this corresponds to. These were data corresponding to a particular SF and TF indexed by r
            
            thisOrigIndex=thisD.r(thisTFIndex,thisSFIndex); % Here is r. It is a combination of the indices into tfList and sfList
            
            thisTF=ceil(thisOrigIndex/nSF); % This should be the actual TF index that was run on this trial.
            thisSF=1+rem(thisOrigIndex,nTF); % This should be the actual SF index that was run on this trial.
            
            timeSeriesData=allRespData.Data((nPreBin*sampleFreq+1):end-(nPostBin*sampleFreq));
          
            fTSData=fft(timeSeriesData);
            inputFreq=thisD.tfList(thisTF);
            outAmplitude2F1(thisTrial,thisTF,thisSF)=fTSData(inputFreq*2*nSecs+1); % Remember, adding 1 to allow for 0 freq in FFT
            outAmplitude1F1(thisTrial,thisTF,thisSF)=fTSData(inputFreq*1*nSecs+1); % Remember, adding 1 to allow for 0 freq in FFT
            outNoise(thisTrial,thisTF,thisSF)=sqrt(sum(abs(fTSData(2:200).^2)));
            
        end % Next SF
    end % Next TF
end % Next trial

%% We can take a quick look like this...
tfList=thisD.tfList;

sfList=thisD.sfList;

mAmp2F1=squeeze(mean(abs(outAmplitude2F1),1));
mAmp1F1=squeeze(mean(abs(outAmplitude1F1),1));
mNoise=squeeze(mean((outNoise),1));

figure(1);
% Plot the raw amplitude of the second harmonic. This might be affected by
% the noise present..
subplot(2,2,1);
imagesc(abs(mAmp2F1))
colorbar
colormap hot;
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
title('Raw 2F1 amplitudes');
set(gca,'YTickLabel',{tfList});
set(gca,'XTickLabel',{(sfList*100)});

% A better thing to do is to compute the 'coherence' - the power at the
% frequency of interest divided by some local measure of noise. Here is the
% noise...
subplot(2,2,2);
imagesc(abs(mNoise));
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
colorbar
colormap hot;title('Overall noise');
set(gca,'YTickLabel',{tfList});
set(gca,'XTickLabel',{(sfList*100)});
% Here's the coherence at the 1st harmonic: photoreceptors? Monitor bias?
subplot(2,2,3);
imagesc(abs(mAmp1F1)./mNoise);
title('1F1 coherence');

colorbar
colormap hot;
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
set(gca,'YTickLabel',{tfList});
set(gca,'XTickLabel',{(sfList*100)});

% Here's the coherence at the 2nd harmonic - neuronal responses?

subplot(2,2,4);
imagesc(abs(mAmp2F1)./mNoise);
title('2F1 coherence');
colorbar
colormap hot;
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
set(gca,'YTickLabel',{tfList});
set(gca,'XTickLabel',{(sfList*100)});