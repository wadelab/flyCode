function [phenotypeData,params]=ss_loadFlyAdaptationData(phenotypeList,extractionParams)
% [phenotypeData,params]=ss_loadFlyAdaptationData(phenotypeList,extractionParams)
%  Extracts data from files containing fly data. Returns summary data from
% requested frequencies in phenotypeData and information about the
% experiment (the params structure) in params.
% This version for use by Jonathan in his MSc project - takes data from
% adaptation experiments where a set of short probe periods are
% interspersed with a long high contrast adaptation period.
% Returns the raw data and the extracted components from the prove periods
%

freqsToExtract=extractionParams.freqsToExtract; % Which frequencies to extract (optional label structure as well)
DOFLYNORM=extractionParams.DOFLYNORM;

%% Here we load in all the different data files.

for thisPhenotype=1:length(phenotypeList)
    
    
    % Go into the directory containing the next phenotype and find out how
    % many 'Fly...' subdirectories it contains.
    
    nFlies=length(phenotypeList{thisPhenotype}.flyDir);
    fprintf('\nLoading data for %d flies\n',nFlies);
    flyMeanWaveform=[];
    flyFTData=[]
    flyExtractedData=[];
    
    
    tic;
    for thisFlyIndex=1:nFlies
        nDataSets=length(phenotypeList{thisPhenotype}.flyData{thisFlyIndex}.fileNames);
        
        probeData=[];
        
        fprintf('\nLoading data for %d datasets in fly %d\n',nDataSets,thisFlyIndex);
        
        for thisFile=1:nDataSets
            % Here we can load in the data. I think we should do this for
            % all file and post-process later.
            fileName=fullfile(phenotypeList{thisPhenotype}.flyDir{thisFlyIndex},phenotypeList{thisPhenotype}.flyData{thisFlyIndex}.fileNames{thisFile});
            disp(fileName);
            
            warning('off','all'); % Suppress Non-fatal warnings that are generated when you try to load DAQ toolbox objects without the DAQ TB installed.
            allData=load(fileName);
            warning('on','all');
            
            
            params=allData.exptParams;
            % Work out when the probe periods are.
            probeTimes=[0,params.adaptDuration+allData.totalSecsPerProbe+params.probeTimesAfterAdapt]; % The first probe adds a constant offset to all subsequent times.
            
            % Now extract the data
            probeTimesSamples=probeTimes*allData.digitizerSampleRate+1;
            probeEndTimesSamples=probeTimesSamples+allData.totalSecsPerProbe*allData.digitizerSampleRate-1;
            
            for thisProbe=1:length(probeTimesSamples)
                probeData(:,thisFile,thisProbe,:)=squeeze(allData.d(probeTimesSamples(thisProbe):probeEndTimesSamples(thisProbe),1,:));
            end
            
            
            % Sort the probeData - undo the randomization
            disp('\nSorting')
            [dummy,sortSeq]=sort(allData.exptParams.randSeq); % sort returns both the sorted array and the indices of the sorted sequence
            probeData(:,thisFile,:,:)=probeData(:,thisFile,:,sortSeq); % Use these indices to sort the actual trial data
            
            
            
            
            
        end % Next file. Then we have a big set of data for this Fly
        
        % Average the probe waveforms across the two bins and different
        % repetitions for each Fly. Ultimately, we can then do a rm ANOVA
        % With the factor being adaptaion status.
        
        % First thing: toss out the first 1000 samples from each probe
        % period: This is the first bin
        
        probeData=probeData((allData.digitizerSampleRate+1):end,:,:,:);
        
        % How big is the data set now?
        [totalSamples,nFiles,nProbes,nTrials]=size(probeData);
        
        % Reshape it so that we can average across bins and files at the
        % same time....
        pData=reshape(probeData,[allData.digitizerSampleRate,((allData.totalSecsPerProbe-1)*nFiles),nProbes,nTrials]);
        
        % Do the averaging down the bins * files dimension
        flyMeanWaveform(:,:,:,thisFlyIndex)=squeeze(mean(pData,2));
        
        % Compute the Fourier transform so that we can analyze the data in
        % the frequency domain.
        flyFTData(:,:,:,thisFlyIndex)=fft(flyMeanWaveform(:,:,:,thisFlyIndex));
        
        % Extract the required frequencies.
        flyExtractedData(:,:,:,thisFlyIndex)= flyFTData((extractionParams.freqsToExtract+1),:,:,thisFlyIndex);
        
        if (DOFLYNORM) % Are we normalizing the data?
            % Normalize the data on a fly by file basis to the average of the top three
            % unadapted, first probe amps.
            
            normVal=(mean(flyExtractedData(:,1,(4:6),:),3)); % What do we normalize >by<? This is a complex average of three probe responses covering the high part of the contrast range. We norm the 1F and 2F independently
                  normFlyExtractedData=flyExtractedData./repmat(normVal,[1,length(probeTimes),nTrials,1]);

        else
            normFlyExtractedData=flyExtractedData;
        end
        
        %end
        
        
    end % Next fly
    
    % Place the combined data for each phenotype into a cell array
    % ('phenotypeData')  and go to the next p'type.
    phenotypeData{thisPhenotype}.normFlyExtractedData=normFlyExtractedData;
    phenotypeData{thisPhenotype}.flyFTData=flyFTData;
    phenotypeData{thisPhenotype}.flyExtractedData=flyExtractedData;
    phenotypeData{thisPhenotype}.meanWaveform=flyMeanWaveform;
    toc
    
end
