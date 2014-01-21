% Modified from runCRF code
% This version will test adaptation in the fly visual system
% The idea is to precede 'probe' constrasts with a period of adaptation.
% We will measure the response to probes of different contrasts and
% look at how the CRF (contrast response function) changes depending on
% adaptation
% Each stimulus period will consist of 10s of adaptation followed by 4s
% bursts of brobe at intervals of 0,10,20,30s
% Recovery time between adaptation will be 1min, then repeat with a
% different adaptation and/or probe contrast level.
% In total we hope to probe 6 different probe contrasts (0,5,10,20,40,80%)
% and 2 adaptation levels (0,90%)
% 16 Jan 2013 ARW and JR wrote it.
% wade@wadelab.net


clear all;
close all;

TESTFLAG=0; % Set this to 1 to indicate that we're testing the script without accessing the hardware.
% Remember to set it to '0' for real experiments!

datadir='.'; % Where you want the data to be saved. On the acquisition computer it's datadir='E:\data\2012\SSERG\';

interExptPauseSecs = 1;

digitizerSampleRate=1000; % Hz

nOutChans=4; % How many LED outputs do we have? Now I >thought< we had 5 LEDs but I get an error if I set this to 5.

offVoltage=5.5; % Volts. At this level the LED is off. Don't ask why it's not 0...

digitizerAmpMode='Differential';

% % Stuff to do with the actual stimulus
% binDuration=1; % One second per bin
% binsPerTrial=3;  % Average this many bins together for each trial
% nPreBins=1; % Add on this many bins at the start of each trial to avoid onset transients.
% nTrials=11; % Number of separate trial conditions. This will span the contrast range.

%% Experiment logging
[metaData,Cancelled]=runFlyInputGUI;   % This requires a function inputsdlg, available from the mathworks central website.
if (Cancelled)
    error('Script cancelled');
end

%% At the moment, the different exptSets are all the same except for the
%% channe that is used. set 1 uses channel 0, set 2 uses channel 1 etc...
%%
% Loop over many reps once you are satisfied with the code
% *************************************************************
exptParams=getFlyExptStructAdapt2(metaData.exptSet); % Get the parameters for all the experiments in a single structure exptParams().
nRepeats=exptParams.nRepeats;

tic
%%
for thisRun=1:nRepeats
    
 
   % Compute the length of an entire trial
    totalSecsPerProbe=exptParams.binsPerTrial+exptParams.nPreBins;
    
    totalTrialDuration=exptParams.adaptDuration+exptParams.probeTimesAfterAdapt(end)+2*totalSecsPerProbe; % This is in seconds. Note we have one probe period at the start and one at the end - that's where the 2xtotalSecsPerProvbe thing comes from.

    
    
    %% ARE WE RUNNING FOR REAL?
    if (~TESTFLAG)    % If we're >not< testing, go ahead and set up the acquisition hardware.
        
        disp('Running experiment...');
        %% INITIALIZE THE RIG
        [ao,ai]=initNIDAQ([offVoltage,offVoltage,offVoltage,offVoltage]); %This is a separate function that zeros out all the outputs. Normally we leave the led on between trials to allow the fly to adapt to mean levels
        
        
        %% Here we set up the trials and run them. We will store data on a
        % per-trial basis and chop it up later.
        
        % Data will be acquired from hardware channels 0 and 1. These are the
        % electrode and the photodiode.
        addchannel(ai, 0);
        addchannel(ai, 1);
        
        %% Set up the input system - we can do this just once per expt: Data will
        % come into the same buffer each time and we can extract it after each
        % trial.

      
        % Configure the analog input
        set(ai,'InputType',digitizerAmpMode);
        ai.SampleRate = digitizerSampleRate; % Rate in samples / second
        ai.SamplesPerTrigger = digitizerSampleRate*totalTrialDuration;
        % Make it a manual trigger and link it to the output trigger
        
        %% Set up the output channels. There are two for now - more perhaps later
        %when we do silent substitution
        % However, there's no reason not to initialize all 5
        chans = addchannel(ao,0:(nOutChans-1));
        set(ao,'SampleRate',digitizerSampleRate);
        ActualRate = get(ao,'SampleRate');
        set([ai ao],'TriggerType','Manual')
        set(ai,'ManualTriggerHwOn','Trigger')
        
    else
        ActualRate=1000;
    end
    
    
    %% Make the waveforms (irrespective of whether we output them or not)
     % We can now make a blank waveform and fill it with zeros...
    
    
    
 
    % Set the first part of waveform to the adaptation sequence.
    
    
    %%
    % Loop over all experiments
    
    disp('Pausing...');
    pause(interExptPauseSecs);
    disp('Running');
    
    len = ActualRate*totalTrialDuration; % We do this because the rate we ask for might not be available. However, if it's not, I'd expect trouble.
    waveform=zeros(len,1); % ActualRate is the output rate (because we got it from ao rather than ai. waveform is in contrast units, not voltage

    
    % Stuff that converts between input voltages and contrast
    contVoltRangeProbe=exptParams.probeContSeq*(offVoltage-exptParams.baselineVoltage); % For each contrast, this is the corresponding voltage modulation.
    contVoltRangeAdapt=exptParams.adaptContSeq*(offVoltage-exptParams.baselineVoltage); %
    
    % Save these values for logging
    % Expt is a big cell array that stores all the information needed to
    % recreate the stimulus + the resulting data
    
    % Now loop over all trials (contrast levels) setting up the output system
    % and acquiring data each time.
    expt=metaData;
    expt.startTime=now;
    
    
    for thisTrial=1:exptParams.nTrials % Loop over all trials. For each trial we reset and recompute the output waveforms.
        % For the adaptation experiment there are 12 trials: 6 contrat
        % levels, 2 adaptation conditions. These are fully randomized.
        
        % For adaptaion, there's only one input (F1). And so we only
        % need to make a single waveform. The only difficulty is that
        % we need to create a structured waveform:
        % [PROBE][ADAPT][PROBE]--[BLANK]--[PROBE]--[PROBE]
        
        % But that's easy!
        
        adaptWaveform=sin(linspace(0,2*pi*exptParams.F*exptParams.adaptDuration,exptParams.adaptDuration*ActualRate))*exptParams.adaptContSeq(thisTrial); % In contrast units
        
        probeWaveform=sin(linspace(0,2*pi*exptParams.F*totalSecsPerProbe,ActualRate*totalSecsPerProbe))*exptParams.probeContSeq(thisTrial);
        
        samplesPerProbeWaveform=length(probeWaveform);
        samplesPerAdaptWaveform=length(adaptWaveform);
        % Begin constructing the actual output contrast sequence. First add
        % the adaptation period to the start of the wave
        waveform(1:samplesPerProbeWaveform)=probeWaveform; % This is the first (reference) probe waveform;
        waveform((samplesPerProbeWaveform+1):(samplesPerProbeWaveform+samplesPerAdaptWaveform))=adaptWaveform; % This is the adaptation period.

        
        % Next loop over all the instances of probes and set those entries
        % in the waveform to probeWaveform
        
        for thisProbeInstance=1:length(exptParams.probeTimesAfterAdapt)
            thisProbeTime=exptParams.probeTimesAfterAdapt(thisProbeInstance)+exptParams.adaptDuration+totalSecsPerProbe; % Note the last addition accounts for the first probe period
            waveform((thisProbeTime*ActualRate):(thisProbeTime+totalSecsPerProbe)*ActualRate-1)=probeWaveform;
        end
        
        % We now have a waveform in contrast units. We just have to convert
        % it to voltages and it's ready to load into the DAC
        
        
        data=repmat(exptParams.chanBaselineArray,len,1); % Here we set up the actual output dataarray. The values in chanBaselineArray are set to 'offVoltage' if there's nothing happening on that channel
     
        
        fprintf('\nRunning trial %d of %d  at adapt contrast %.3g, probe contrast %.3g',thisTrial,exptParams.nTrials, exptParams.adaptContSeq(thisTrial),exptParams.probeContSeq(thisTrial));
        %% Now set up the output system
        
        thisModVoltage=offVoltage-exptParams.chanBaselineArray(1); % For now we are using only channel 1
        
     
            %data=ones(len,2)*offVoltage; % Output 2 channels just because we have already set them up...
            
            data(:,1)=thisModVoltage*waveform+exptParams.chanBaselineArray(1);
     
        
            data(end,1)=exptParams.chanBaselineArray(1); % Set to mean at the end, not zero
       
        
        %Do some bounds checking on 'data' - should always be between 0 and
        %offVoltage.
        if (min(data(:))<0 || max(data(:))>offVoltage)
            disp('**** WARNING - output buffer contains out-of-bounds values. This should really be an error... *****');
        end
        
        
        if (~TESTFLAG)
            putdata(ao,data) % Put the data (waveform) into the object. A column of data for each channel
            
            start([ai ao]) % Initialize the objects
            trigger([ai ao]) % Acqire data
            wait(ao,totalTrialDuration+1); % Wait 'till it's all over
            
            d(:,:,thisTrial)=getdata(ai);
        else  % If we're just testing, fill the output with random numbers.
            d(:,:,thisTrial)=rand(len,2);
        end
        
    end
    
    % Save details of this particular experiment, then move on to the next
    % one.
    expt.exptParams=exptParams;
    expt.startTimeString=datestr(expt.startTime);
    expt.endTime=now;
    expt.endTimeString=datestr(expt.endTime);
    
    
    
    
    %% Save out the data
    save('temp');
    
    filename=fullfile(datadir,[expt.FlyID,'_Ch',int2str(exptParams.LEDChannel(1)),'_',int2str(thisRun),'_',datestr(expt.startTime,30),'.mat'])
    save(filename);
    
    % The data are great, but the order of the contrast settings might
    % (probably >is<) randomized.
    % The random sequences are stored in expt{[experiment]}.randSeq(:,[input])
    % When we plot the data, we want to >undo< this randomiztion
    
    % Turn off the NIDAQ
    if (~TESTFLAG)
        initNIDAQ(5.5); %This is a separate function that zeros out all the outputs. Normally we leave the led on between trials to allow the fly to adapt to mean levels
    end
    
    
    %% Look at raw data
    figure(1);
    subplot(2,1,2);
    imagesc((squeeze(d(:,1,:))));
    subplot(2,1,2);
    imagesc((squeeze(d(:,2,:))));
    return
    %%
    %% From this point on, everything is just plotting - it could be moved to
    % another script. It should be self-contained.
    % I think that one of the channels is currently showing the output of the
    % photodiode, the other is showing the output of the ADC that's driving
    % the LED. So one should be a perfect sine wave. The other should be more
    % or less perfect.
    
    
    % Condition it a bit. Chop out bins
    condDat=d((digitizerSampleRate*nPreBins+1):end,:,:);
    % Reformat into bins
    condDat=reshape(condDat,[digitizerSampleRate,exptParams{1}.binsPerTrial,2,exptParams{1}.nTrials,length(exptParams)]);
    
    % Compute the average across bins. This throws away bin-to-bin information
    meanCondDat=squeeze(mean(condDat,2));
    %This is samplesperbin * nChannels * nContrasts * nExpts
    % Here we can re-order meanCondDat to generate plots in order of contrast.
    for thisExpt=1:length(exptParams)
        [dummy,sortSeq{thisExpt}]=sort(exptParams{thisExpt}.randSeq(:,1));
        condDat(:,:,:,:,thisExpt)=condDat(:,:,:,sortSeq{thisExpt},thisExpt);
        meanCondDat(:,:,:,thisExpt)=meanCondDat(:,:,sortSeq{thisExpt},thisExpt);
    end
    
    % Image the data
    figure(1); subplot(2,1,1);
    imagesc(squeeze(meanCondDat(:,1,:,1))); colorbar; axis off;
    subplot(2,1,2);
    imagesc(squeeze(meanCondDat(:,2,:,1))); colorbar; axis off;
    colormap hot;
    
    
    
    
    %% Compute FFTs and look at the 1F1 and 1F2 components
    fftData=fft(meanCondDat);
    % disp('1F1 magnitude');
    % disp(abs(squeeze(fftData(1+F1,:,:,:))));
    % disp('2F1 magnitude');
    % disp(abs(squeeze(fftData(1+F1*2,:,:,:))));
    
    % Do the thing below to fit log contrast onto a plot
    
    contRange1=exptParams{1}.contRange(sortSeq{1},1);
    contRange2=contRange1
    
    contRange1(1,:)=0.01;
    contRange2(1,:)=0.01;
    % Compute the distortion in the output, input.
    F1=exptParams{1}.F(1);
    F2=exptParams{2}.F(2);
    
    distortion=abs(squeeze(fftData(1+F1*2,:,:,:)))./abs(squeeze(fftData(1+F1,:,:,:)));
    % Note: the first value (for 0 contrast) is not very meaningful.
    figure(2);
    subplot(1,2,1);hold off;
    f1Plot1=plot(contRange1(:),abs(squeeze(fftData(1+F1,1,:,1))),'k');
    hold on;
    f1Plot2=plot(contRange1(:),abs(squeeze(fftData(1+F1,1,:,2))),'r');
    set(gca,'XScale','Log');
    ylabel('F1 Amplitude');
    xlabel('Contrast');
    grid on
    subplot(1,2,2);
    hold off;
    f2Plot1=plot(contRange1(:),abs(squeeze(fftData(1+F1*2,1,:,1))),'k');
    hold on
    f2Plot2=plot(contRange1(:),abs(squeeze(fftData(1+F1*2,1,:,2))),'r');
    set(gca,'XScale','Log');
    grid on;
    ylabel('F2 Amplitude');
    xlabel('Contrast');
    set(f1Plot1,'LineWidth',2);
    set(f2Plot1,'LineWidth',2);
    set(f1Plot2,'LineWidth',2);
    set(f2Plot2,'LineWidth',2);
    
    % Save this as a JPEG
    imageName=fullfile(datadir,[expt{thisExpt}.FlyID,'_Ch',int2str(exptParams{1}.LEDChannel(1)),'_',int2str(thisRun),'_',datestr(expt{thisExpt}.startTime,30),'.jpg'])
    print(gcf,'-djpeg',imageName);
    
    
    %%
    % Plot some extra figures: Specifically, we'd like to see what a single bin
    % looks like
    figure(3);
    plot(squeeze(meanCondDat(:,1,exptParams{1}.nTrials,2)));
    title('1 Bin of data');
    grid on;
    
    figure(5);
    imagesc(data);
    colorbar;
    title('Last output buffer');
    
end % Outside loop on overall number of repeats
toc

