function [phenotypeData,params]=ss_loadFlyData(phenotypeList,extractionParams)
%  [phenotypeData,params]=ss_loadFlyData(phenotypeList,extractionParams)
%  Extracts data from files containing fly data. Returns summary data from
% requested frequencies in phenotypeData and information about the
% experiment (the params structure) in params.
%
%

freqsToExtract=extractionParams.freqsToExtract; % Which frequencies to extract (optional label structure as well)

nFreqs=extractionParams.incoherentAvMaxFreq; % Cutoff for incoherent averaging
rejectParams=extractionParams.rejectParams; % Noise rejections parameters
%DOFILENORM=extractionParams.DOFILENORM;
%SNRFLAG=extractionParams.SNRFLAG;
waveformSampleRate=extractionParams.waveformSampleRate; % Resample the average waveform to this rate irrespective of the initial rate.

%% Here we load in all the different data files.

for thisPhenotype=1:length(phenotypeList)
    
    
    % Go into the diirectory containing the next phenotype and find out how
    % many 'Fly...' subdirectories it contains.
    
    nFlies=length(phenotypeList{thisPhenotype}.flyDir);
    
    
    tic;
    for thisFlyIndex=1:nFlies
        nDataSets=length(phenotypeList{thisPhenotype}.flyData{thisFlyIndex}.fileNames);
        
        condDat=[];
        meanSpect=[];
        for thisFile=2:nDataSets % 2:nDataSets % Skip the first one - light adaptation!
         
        %for thisFile=nDataSets:nDataSets;
            % Here we can load in the data. I think we should do this for
            % all file and post-process later.
            fileName=fullfile(phenotypeList{thisPhenotype}.flyDir{thisFlyIndex},phenotypeList{thisPhenotype}.flyData{thisFlyIndex}.fileNames{thisFile});
            fprintf('\nLoading %s\n',fileName);
            
            warning('off','all'); % Suppress Non-fatal warnings that are generated when you try to load DAQ toolbox objects without the DAQ TB installed.
                allData=load(fileName);
            warning('on','all');
            
            params=allData.exptParams{1};
            % allData has a lot of stuff in it. Everything in fact.
            % We don't need it all - just the waveforms and some
            % information about F1,F2, bins...
            % allData.d is the most useful representation of the
            % data. It is samples  x channels x
            % contrastLevels x maskConditions
            nPreBins=params.nPreBins;
            sampleRate=allData.ActualRate;
            nTrials=params.nTrials;
            nExpts=length(allData.exptParams);
           
            binsPerTrial=params.binsPerTrial;
            rawPerFileData=reshape(squeeze(allData.d((sampleRate*nPreBins+1):end,1,:,:)),[sampleRate,binsPerTrial,nTrials,nExpts]); % This gets rid of the first 'pre' bins...
            
            size(rawPerFileData)
            size(condDat)
            
            
            condDat(:,:,:,:,thisFile)=rawPerFileData;
            
            
            % Sort the condDat - undo the randomization
            disp('\nSorting')
            for thisExpt=1:nExpts
                [dummy,sortSeq{thisExpt}]=sort(allData.exptParams{thisExpt}.randSeq(:,1));
                condDat(:,:,:,thisExpt,thisFile)=condDat(:,:,sortSeq{thisExpt},thisExpt,thisFile);
            end
  
            
        end % Next file. Then we have a big set of bins

        % At this point we need to do averaging across the
        % bins. And to do >this< we must identify bad bins
        
        %badBinFlags=ss_noiseCheck(condDat,params,rejectParams);  %% Check for noise
        %fprintf('\n%d bins (%2.2g %% rejected as bad.\n',sum(badBinFlags(:)),sum(badBinFlags(:))/prod(size(badBinFlags))*100);
        
        %max(badBinFlags(:))
        %min(badBinFlags(:))
        %sum(isnan(badBinFlags(:)))
        
        
        % Replace bad bins with NaNs
        %if (sum(badBinFlags(:))>0)
        %    condDat(:,find(badBinFlags))=NaN;
        %end
        
        % Cond dat at this point is sampleRate * nBins * nConts * nExpts * nFiles
        % Make an average waveform for a single bin across all files, bins.
        avWaveform=squeeze(nanmean(condDat,2)); % Average down bins
        avWaveform=squeeze(nanmean(avWaveform,4)); % Average across files
        
        % Do some resampling to match the requested waveformSampleRate
        currRate=size(avWaveform,1);
        size(avWaveform)
        
        clear avWaveformRS;
        
        for thisExpt=1:nExpts
            avWaveformRS(:,:,thisExpt)=resample(avWaveform(:,:,thisExpt),waveformSampleRate,currRate);
        end
        
        size(avWaveformRS)
        
        
        flyMeanWaveform{thisPhenotype}.data(:,:,:,thisFlyIndex)=avWaveformRS;

        
        fCondDat=(fft(condDat)/((size(avWaveform,1)))); % Compute FT down time in each bin. Leave in complex domain. Do scaling by that strange factor to maintain plotting compatibility with very old datasets
  
        meanSpect=squeeze(nanmean(abs(fCondDat(2:nFreqs,:,:,:,:)),2));
        compMeanSpect=squeeze(nanmean((fCondDat(2:nFreqs,:,:,:,:)),2));
        
        flyMeanSpectrum{thisPhenotype}.data(:,:,:,thisFlyIndex)=squeeze(nanmean(meanSpect,4));% Average across files for a single fly
        flyCompMeanSpectrum{thisPhenotype}.data(:,:,:,thisFlyIndex)=squeeze(nanmean(meanSpect,4)); % The same frequency domain average but with complex vals.
        
        
        
        
        
        computedFreqsToExtract=abs(params.F(1)*freqsToExtract(:,1)+params.F(2)*freqsToExtract(:,2)); % Which frequencies are we going to extract
        params.extractedFreqs=computedFreqsToExtract;
        
        computedNoiseSideBands=[computedFreqsToExtract(:)+1,computedFreqsToExtract(:)-1]; % It is up to you to arrange the Fs so that this is meaningful
        computedAllNoiseBands=setdiff([1:100],computedFreqsToExtract); % The noise is everything else
        
        noiseVals1=fCondDat(computedNoiseSideBands(:,1)+1,:,:,:,:);
        noiseVals2=fCondDat(computedNoiseSideBands(:,2)+1,:,:,:,:);
        allNoiseVals=fCondDat(computedAllNoiseBands+1,:,:,:,:);
        
        
        fCondDat=fCondDat(computedFreqsToExtract+1,:,:,:,:); % Add 1 to the freqs to offset the mean baseline in the FFT
        
        binAverageNoise1=squeeze(nanmean(noiseVals1,2));
        binAverageNoise2=squeeze(nanmean(noiseVals2,2));
        binAverage=squeeze(nanmean(fCondDat,2));
        rmsSideBandNoise=sqrt(binAverageNoise1.^2+binAverageNoise2.^2);
        rmsAllNoise=sqrt(nanmean(allNoiseVals(:).^2));

       
        meanData=squeeze(nanmean(binAverage,4));
        meanNoise=squeeze(nanmean(rmsSideBandNoise,4));
        SNRFLAG=0;
        switch SNRFLAG
            case 1
           meanData=meanData./(meanNoise);
            case 2
                meanData=meanData./rmsAllNoise;
            otherwise
                % Do nothing
        end

        
        phenotypeData{thisPhenotype}.fly{thisFlyIndex}.allfCondDat=meanData; % Average in the complex fourier domain across bins


    end % Next fly
    
    
    
        phenotypeData{thisPhenotype}.meanSpectrum=nanmean(flyMeanSpectrum{thisPhenotype}.data,4);
        phenotypeData{thisPhenotype}.semSpectrum=nanstd(flyMeanSpectrum{thisPhenotype}.data,[],4)/sqrt(size(flyMeanSpectrum{thisPhenotype}.data,4));
        phenotypeData{thisPhenotype}.meanCompSpectrum=nanmean(flyCompMeanSpectrum{thisPhenotype}.data,4);
        phenotypeData{thisPhenotype}.avWaveform=nanmean(flyMeanWaveform{thisPhenotype}.data,4);
        
    
    toc
    
end
