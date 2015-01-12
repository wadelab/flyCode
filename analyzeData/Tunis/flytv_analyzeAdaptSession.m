%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;
fList=dir(fullfile(dataDir,'*.mat'))

nSessions=length(fList);
% Generate an empty matrix of NaNs

%%
for thisSession=1:nSessions
    fName=fullfile(dataDir,fList(thisSession).name)
    
    
    dataSetName=fullfile(fName); % Fullfile generates a legal filename on any platform
    
    thisD=load(dataSetName);
    [nRepeats,nConditions,nSegments]=size(thisD.dataOut.data)% Data is saved as a cell array that is nReps x nConditions x nSegments. nReps=repetitions, nConditions= e.g. (SOM Adapt, SOM Probe), nSegments=(adapt,probe...)
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
                
                segData=thisD.dataOut.data{thisRep,thisCondition,thisSegment};
                segCatData{thisSegment}(thisRep,thisSession,:,:,thisCondition)=segData;
                
                
            end
        end
    end
    
   
end % Next session
   
% We now have a cell array that is 
% {nSegments} each with
% nReps x nSessions x nTimePoints x nChannels x nConditions
   