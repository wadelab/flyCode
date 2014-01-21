function [phenotypeData,params]=fly_loadSSData(subDirList,extractionParams)
%  [phenotypeData,params]=fly_loadSSData(subDirList,extractionParams)
%  Extracts data from files containing fly data. Returns summary data from
% requested frequencies in phenotypeData and information about the
% experiment (the params structure) in params.
% This is a complete re-write of ss_loadFly.... 
% Now works with new stimulus system, arbitrary mixing of background /
% foreground contrasts etc.
%
% Data are held in a structure loaded from a .mat file
freqsToExtract=extractionParams.freqsToExtract; % Which frequencies to extract (optional label structure as well)
nFreqs=extractionParams.incoherentAvMaxFreq; % Cutoff for incoherent averaging
rejectParams=extractionParams.rejectParams; % Noise rejections parameters

waveformSampleRate=extractionParams.waveformSampleRate; % Resample the average waveform to this rate irrespective of the initial rate.

%% Here we load in all the different data files.
overallExptIndex=1;
for thisSubDir=1:length(subDirList) % The concept of individual directories for different phenotypes is a little redundant now since all the ptype info is held in the file itself.
                                          % And we can run multiple flies
                                          % in a single session. However,
                                          % we keep it as a concept because
                                          % it help users organize their
                                          % data.
                                          
    
    
    % Go into each subdirectory and find out how many 
    % many 'Fly...' or 'Expt...' subdirectories it contains.
    
    nExpts=length(subDirList{thisSubDir}.exptDir);
    
    
    tic;
    for thisExptIndex=1:nExpts
        nDataSets=length(subDirList{thisSubDir}.exptData{thisExptIndex}.fileNames);
        
        condDat=[];
        meanSpect=[];
        
        for thisFile=2:nDataSets % Load in all the files in the directory
            
            % Here we can load in the data. I think we should do this for
            % all file and post-process later.
            fileName=fullfile(subDirList{thisSubDir}.exptDir{thisExptIndex},subDirList{thisSubDir}.exptData{thisExptIndex}.fileNames{thisFile});
            disp(fileName);
            
            warning('off','all'); % Suppress Non-fatal warnings that are generated when you try to load DAQ toolbox objects without the DAQ TB installed.
            allData=load(fileName);
            warning('on','all');
         
            params=allData.exptParams; %  a struct containing experiment-relevent information
            % We don't need it all - just the waveforms and some
            % information about F1,F2, bins...
            % allData.d is the most useful representation of the
            % data. It is samples  x channels x
            % contrastLevels x maskCondition
            
            nPreBins=params.nPreBins;
            sampleRate=allData.digitizerSampleRate;
            nTrials=size(allData.d,3); % How many probe and mask conditions in total
           
            nChannels=length(extractionParams.dataChannelIndices);% In general we have 2 input channels - 1 and 3. The middle channel here is the photodiode which is a useful check on input linearity.
          
            
            
            binsPerTrial=params.binsPerTrial;
            rawPerFileData=reshape(squeeze(allData.d((sampleRate*nPreBins+1):end,extractionParams.dataChannelIndices,:)),[sampleRate,binsPerTrial,nChannels,nTrials]); % This gets rid of the first 'pre' bins...
            
            condDat(:,:,:,:,thisFile)=rawPerFileData;
            
            % Sort the condDat - undo the randomization of contrast levels
                [dummy,sortSeq]=sort(allData.exptParams.randSeq);
                condDat(:,:,:,:,thisFile)=condDat(:,:,:,sortSeq,thisFile);

            
        end % Next file. Then we have a big set of bins
       
        
        allOutData(overallExptIndex)=fly_parseGUIPhenotypeFields(params.b);
        
        
            
        % Cond dat at this point is sampleRate * nBins * nChannels * nConts * nFiles
        % Make an average waveform for a single bin across all files, bins.
        avWaveform=squeeze(nanmean(condDat,2)); % Average down bins
        avWaveform=squeeze(nanmean(avWaveform,4)); % Average across files - all averaging is coherent.
         
        % Do some resampling to match the requested waveformSampleRate
        currRate=size(avWaveform,1);
       
        
        clear avWaveformRS;
        if (currRate ~= waveformSampleRate)
            avWaveformRS=resample(avWaveform,waveformSampleRate,currRate);
        else
            avWaveformRS=avWaveform;
             
        end
        
        flyMeanWaveform{thisSubDir}.data(:,:,:,thisExptIndex)=avWaveformRS; % This now has both channels  in

        % We also want to do something else: Extract fourier domain
        % components. We do this in two ways: Coherently (which is really
        % just the FT of the time-average computed above). And incoherently
        % where we want to discard phase information in each bin so that we preserve
        % endogenous noise power. 
        
        fCondDat=fft(condDat)/(size(condDat,1)); % Compute FT down time in each bin. Leave in complex domain. Technically, we account for the length of the sample waveform although this is always the same...
        
        
        meanSpect=squeeze(nanmean(abs(fCondDat(2:nFreqs,:,:,:,:)),2));
        compMeanSpect=squeeze(nanmean((fCondDat(2:nFreqs,:,:,:,:)),2));
        
        flyMeanSpectrum{thisSubDir}.data(:,:,:,thisExptIndex)=squeeze(nanmean(meanSpect,4));% Average across files for a single fly
        flyCompMeanSpectrum{thisSubDir}.data(:,:,:,thisExptIndex)=squeeze(nanmean(compMeanSpect,4)); % The same frequency domain average but with complex vals.
        
         
        
        
        
        computedFreqsToExtract=abs(params.F(1).Freq*freqsToExtract(:,1)+params.F(2).Freq*freqsToExtract(:,2)); % Which frequencies are we going to extract
        
        params.extractedFreqs=computedFreqsToExtract;
        
     
     
        
        fCondDat=(fCondDat(computedFreqsToExtract+1,:,:,:,:)); % Add 1 to the freqs to offset the mean baseline in the FFT
       
    
        
     
        meanDat=squeeze(mean(fCondDat,2));
        meanDat=squeeze(mean(meanDat,4));
          
        
        phenotypeData{thisSubDir}.expt{thisExptIndex}.allfCondDat=meanDat; % Average in the complex fourier domain across bins, then across repetitions
      

        overallExptIndex=overallExptIndex+1;

    end % Next expt
    
        phenotypeData{thisSubDir}.meanSpectrum=nanmean(flyMeanSpectrum{thisSubDir}.data,4);
        phenotypeData{thisSubDir}.semSpectrum=nanstd(flyMeanSpectrum{thisSubDir}.data,[],4)/sqrt(size(flyMeanSpectrum{thisSubDir}.data,4));
        phenotypeData{thisSubDir}.meanCompSpectrum=nanmean(flyCompMeanSpectrum{thisSubDir}.data,4);
        phenotypeData{thisSubDir}.avWaveform=nanmean(flyMeanWaveform{thisSubDir}.data,4);
        
    

    
end
params.outType=allOutData;
