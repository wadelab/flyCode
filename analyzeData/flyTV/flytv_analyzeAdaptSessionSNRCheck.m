%%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all; % Clear all vairables
close all; % Close all figures
dataDir=uigetdir; % GUI to select a directory where the data files are stored
fList=dir(fullfile(dataDir,'*.mat')) % List all the files in that directory and save them to a structure. The first two are '.' and '..' normally but here we only list things ending in .mat

nSessions=length(fList); % How many files do we have?


%%
for thisSession=1:nSessions % Loop over all sessions
    fName=fullfile(dataDir,fList(thisSession).name)
    
    dataSetName=fullfile(fName); % Fullfile generates a legal filename on any platform
    
    thisD=load(dataSetName); % because these are .mat files they just load into matlab
    [nConditions,nRepeats,nSegments]=size(thisD.dataOut.data)% Data are saved as a cell array that is nReps x nConditions x nSegments. nReps=repetitions, nConditions= e.g. (SOM Adapt, SOM Probe), nSegments=(adapt,probe...)
    % Each element of that array is nTimePoints x 2 (channels)
    
    % Loop over repeats averaging data from similar segments 
    
    % Start from the segment level: Generate multidimensional arrays that
    % will ultimately be nRepeats x nTimePoints x nChannels x nConds 
    % There will be one of these per data segment.
    % You can average down dim 1 to find mean over all repeats.
    % 
    for thisSegment=1:nSegments % Note: data can be different lengths in different segments
        for thisCondition=1:nConditions
            for thisRep=1:nRepeats
                
                segData=thisD.dataOut.data{thisCondition,thisRep,thisSegment};
                segCatData{thisSegment}(thisRep,thisCondition,:,:,thisSession)=segData;
                
                
            end
        end
    end
    
   
end % Next session
   
%% We now have a cell array that is 
% {nSegments} each with
% nReps  x nConds x nTimePoints x nChannels x nSessions
% segCatData{1} contains the adaptation data, segCatData{2} contains the
% probes.
% For now, I'm interersted in the adapt sections because we want to know,
% firstly, if we're getting a direction reversal response.

adaptData=segCatData{2};
croppedData=adaptData(:,:,1:4000,:,:); % This crops out a subset of the timeseries. There are 1000 samples per second...


% Average across reps
meanAdaptData=squeeze(mean(croppedData,1));
% We now have data from nSessions x nChannels individual flies. Break this
% into separate flies...
[nConds,nTimePoints,nChannels,nSessions]=size(meanAdaptData)

meanAdaptFlyData=meanAdaptData(1:nConditions,1:nTimePoints,:);

% Now compute ffts on inidividual bins and average across those
nSamplesPerBin=1000; % This is a fact about the digitizer, it works at 1000hz
nBins=nTimePoints/nSamplesPerBin;
nFlies=nSessions*nChannels;
binnedData=reshape(meanAdaptFlyData,[nConds,nSamplesPerBin,nBins,nFlies]);
ftBinData=(fft(binnedData(:,:,2:nBins,:),[],2));
% Aveage across bins 
meanBinnedData=squeeze(mean(ftBinData,3));


% Let's take a look at the 16Hz response for all flies in the first
% condition.
rawProbeResponse=squeeze(meanBinnedData(1,17,:));
rawNoiseAroundProbe=squeeze(meanBinnedData(1,[15 16 18 19],:));
rmsNoise=squeeze(sqrt(mean(abs(rawNoiseAroundProbe).^2)));

snrProbe=abs(rawProbeResponse)./rmsNoise'; % The tick at the end flips the direction of the second vector to match the other one
goodFlies=find(snrProbe>5)

meanBinnedData=meanBinnedData(:,:,goodFlies);
goodBinnedTS=binnedData(:,:,:,goodFlies);
% Plot the mean (across flies) time series for the different conditions
figure (98);
for thisPlot=1:4 % POlot different conditions in different windows
    subplot(4,1,thisPlot)
    plot(squeeze(mean(goodBinnedTS(thisPlot,126:end,:,:),4)));
end


% Average across flies
flyBin=squeeze((mean((meanBinnedData),3)));
semBinnedData=squeeze(std((meanBinnedData),[],3))/sqrt(nFlies);
figure(2);

g=barweb(squeeze(abs(flyBin(:,2:51)))',squeeze(semBinnedData(:,2:51))',1,[],'Probe responses','Frequency','Amp',bone,[],{'NoAdapt','AdaptL','Ctrl','AdaptR'});
axis on

% Whatever... now let's take a look at the first second after the
% adaptation. 
% We know that there's a big transient that happens on the adapt/probe
% change.
% This is over by about 125ms. 
% How about we do our analysis on the time periods after that in just the
% first second
%%
croppedTSDataNoTransient=squeeze(goodBinnedTS(:,1:end,3,:));
% Do the FFT just on this. Now we have cropped out two full data cycles so
% the peaks will be in different places.
ftDataCropped=fft(croppedTSDataNoTransient,[],2);
% Average across flies
meanftDataCropped=squeeze(mean(ftDataCropped,3));
semCroppedData=squeeze(std(ftDataCropped,[],3))/sqrt(nFlies);

figure(80);
g2=barweb(squeeze(abs(meanftDataCropped(:,2:29)))',squeeze(semCroppedData(:,2:29))',1,[],'Probe responses','Frequency','Amp',bone,[],{'NoAdapt','AdaptL','Ctrl','AdaptR'});



   