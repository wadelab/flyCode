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
% nReps  x nConds * nTimePoints x nChannels x nSessions
% segCatData{1} contains the adaptation data, segCatData{2} contains the
% probes.
% For now, I'm interersted in the adapt sections because we want to know,
% firstly, if we're getting a direction reversal response.

adaptData=segCatData{2};
% The size of this is nCondDypes x nSessions x nTimePoints x nChannels x
% nReps

% Average across reps
meanAdaptData=squeeze(mean(adaptData,1));
% We now have data from nSessions x nChannels individual flies. Break this
% into separate flies...
[nConds,nTimePoints,nChannels,nSessions]=size(meanAdaptData)

meanAdaptFlyData=meanAdaptData(1:nConditions,1:nTimePoints,:);

% Now compute ffts on inidividual bins and average across those
nSamplesPerBin=1000;
nBins=nTimePoints/nSamplesPerBin;
nFlies=nSessions*nChannels;
binnedData=reshape(meanAdaptFlyData,[nConds,nSamplesPerBin,nBins,nFlies]);
ftBinData=(fft(binnedData(:,:,2:nBins,:),[],2));
meanBinnedData=squeeze(mean(ftBinData,3));

% Average across flies
flyBin=squeeze((mean((meanBinnedData),3)));
semBinnedData=squeeze(std((meanBinnedData),[],3))/sqrt(nFlies);
figure(2);

g=barweb(squeeze(abs(flyBin(:,2:20)))',squeeze(semBinnedData(:,2:20))',1,[],'Probe responses','Frequency','Amp',bone,[],{'NoAdapt','AdaptL','Ctrl','AdaptR'});
axis on

   